from __future__ import annotations

from collections.abc import Mapping
from typing import Any

import ee
import pandas as pd
import time
from tqdm.auto import tqdm


def df_to_fc(df: pd.DataFrame, lat_colname: str = 'lat',
             lon_colname: str = 'lon') -> ee.FeatureCollection:
    '''Create a ee.FeatureCollection from a pd.DataFrame.

    Args
    - csv_path: str, path to CSV file that includes at least two columns for
        latitude and longitude coordinates
    - lat_colname: str, name of latitude column
    - lon_colname: str, name of longitude column

    Returns: ee.FeatureCollection, contains one feature per row in the CSV file
    '''
    # convert values to Python native types
    # see https://stackoverflow.com/a/47424340
    df = df.astype('object')

    ee_features = []
    for i in range(len(df)):
        props = df.iloc[i].to_dict()

        # oddly EE wants (lon, lat) instead of (lat, lon)
        _geometry = ee.Geometry.Point([
            props[lon_colname],
            props[lat_colname],
        ])
        ee_feat = ee.Feature(_geometry, props)
        ee_features.append(ee_feat)

    return ee.FeatureCollection(ee_features)


def surveyyear_to_range(year: int) -> tuple[str, str]:
    '''Returns the start and end dates for a 3-year range centered on a given
    year.

    Used for filtering satellite images for a survey from the specified year.

    Args
    - year: int, year that survey was started

    Returns
    - start_date: str, start date for filtering satellite images (yyyy-mm-dd)
    - end_date: str, end date for filtering satellite images (yyyy-mm-dd)
    '''
    if not (1996 <= year <= 2019):
        # don't allow 2020 surveys because we don't have all of 2021 imagery
        # yet, so we can't do a true 3-year composite centered on 2020
        raise ValueError(f'Invalid survey_year: {year}. '
                         'Must be between 1996 and 2019 (inclusive)')

    start_year = year - 1
    end_year = year + 1
    start_date = f'{start_year}-01-01'
    end_date = f'{end_year}-12-31'
    return start_date, end_date


def mask_qaclear(img: ee.Image) -> ee.Image:
    '''Masks out pixels of cloud-shadow, snow, and cloud.

    Masks are specified as a floating-point value in the range [0, 1]
    (invalid = 0, valid = 1). See documentation for ee.Image.updateMask():
    https://developers.google.com/earth-engine/apidocs/ee-image-updatemask.

    Pixel QA Bit Flags (universal across Landsat 5/7/8)
    Bit  Attribute
    0    Fill
    1    Clear  (meaning: not water, not cloud shadow, not snow, not cloud)
    2    Water
    3    Cloud Shadow
    4    Snow
    5    Cloud

    For more information on the QA flags, see the Landsat Land Surface
    Reflectance Code product guides from the USGS website:
    - Landsat 4-7 Collection 1 (C1) Surface Reflectance (LEDAPS) Product Guide
        https://www.usgs.gov/media/files/landsat-4-7-collection-1-surface-reflectance-code-ledaps-product-guide
    - Landsat 8 Collection 1 (C1) Land Surface Reflectance Code (LaSRC) Product Guide
        https://www.usgs.gov/media/files/landsat-8-collection-1-land-surface-reflectance-code-product-guide

    Args
    - img: ee.Image, Landsat 5/7/8 image containing 'pixel_qa' band

    Returns
    - img: ee.Image, input image with cloud, cloud-shadow, and snow pixels
        masked out
    '''
    qa = img.select('pixel_qa')
    qa_bands = {
        # 'is_clear':         qa.bitwiseAnd(1 << 1).eq(1),  # 0 = not clear,  1 = clear
        # 'not_water':        qa.bitwiseAnd(1 << 2).eq(0),  # 0 = not water,  1 = water
        'not_cloud_shadow': qa.bitwiseAnd(1 << 3).eq(0),  # 0 = not shadow, 1 = shadow
        'not_snow':         qa.bitwiseAnd(1 << 4).eq(0),  # 0 = not snow,   1 = snow
        'not_cloud':        qa.bitwiseAnd(1 << 5).eq(0),  # 0 = not cloud,  1 = cloud
    }
    return (
        img
        .updateMask(qa_bands['not_cloud'])
        .updateMask(qa_bands['not_cloud_shadow'])
        .updateMask(qa_bands['not_snow'])
    )


def add_latlon(img: ee.Image) -> ee.Image:
    '''Creates a new ee.Image with 2 added bands of longitude and latitude
    coordinates named 'LON' and 'LAT', respectively.
    '''
    latlon = ee.Image.pixelLonLat().select(
        opt_selectors=['longitude', 'latitude'],
        opt_names=['LON', 'LAT'])
    return img.addBands(latlon)


DMSP_IMGS = {
    'F12_19960316-19970212_V4':
        {'start': 1996, 'end': 1997, 'bias':  4.336, 'slope': 0.915},
    'F12_19990119-19991211_V4':
        {'start': 1998, 'end': 1999, 'bias':  1.423, 'slope': 0.780},
    'F12-F15_20000103-20001229_V4':
        {'start': 2000, 'end': 2001, 'bias':  3.658, 'slope': 0.710},
    'F14-F15_20021230-20031127_V4':
        {'start': 2002, 'end': 2003, 'bias':  3.736, 'slope': 0.797},
    'F14_20040118-20041216_V4':
        {'start': 2004, 'end': 2004, 'bias':  1.062, 'slope': 0.761},
    'F16_20051128-20061224_V4':
        {'start': 2005, 'end': 2008},
    'F16_20100111-20101209_V4':
        {'start': 2009, 'end': 2010, 'bias':  2.196, 'slope': 1.195},
    'F16_20100111-20110731_V4':
        {'start': 2011, 'end': 2011, 'bias': -1.987, 'slope': 1.246},
}


def composite_nl(year: int) -> ee.Image:
    '''Creates a nightlights (NL) image.

    For DMSP (years 1996-2011), selects the closest one of the 8 readily
        available yearly composites. Performs inter-annual calibration.

        See: https://eogdata.mines.edu/dmsp/radcal_readme.txt OR
             https://www.ngdc.noaa.gov/eog/dmsp/download_radcal.html.

        Table 3. Inter-annual Calibration Coefficients

        Equation
        Y=Coeff0+Coeff1*X

        Y-File
        F16_20051128-20061224_rad_v4

        X-File                           Pow Coeff0  Coeff1 R2    N_Pt
        F12_19960316-19970212_rad_v4     1   4.336   0.915  0.971 20540
        F12_19990119-19991211_rad_v4     1   1.423   0.780  0.980 20846
        F12-F15_20000103-20001229_rad_v4 1   3.658   0.710  0.980 20866
        F14-F15_20021230-20031127_rad_v4 1   3.736   0.797  0.980 20733
        F14_20040118-20041216_rad_v4     1   1.062   0.761  0.984 20844
        F16_20100111-20101209_rad_v4     1   2.196   1.195  0.981 20848
        F16_20100111-20110731_rad_v4     1  -1.987   1.246  0.981 20848

    For VIIRS (years 2012+), we would ideally want to use the "official" annual
    composites ("Annual VNL V2"). However, these are not on Google Earth Engine
    as of 2021-08-11 (see https://issuetracker.google.com/issues/185928472).
    Therefore, we create our own 3-year median-composite from the monthly
    cloud-free composites. We have 2 options:

        "VCMSLCFG" (VCMSL configuration): used in Nat Comms. (2020) paper
        - "SL" is short for "stray-light corrected," meaning that some images
            with stray light are included in the composite after correction
        - the stray-light correction is used to increase coverage near the
            poles, where data tends to be more sparse

        "VCMCFG" (VCM configuration): this is what we use here
        - This config excludes all data impacted by stray light before creating
          the composite and is therefore higher quality, but has less data
          coverage near the poles. However, since I am using 3-year annual
          composites, data coverage is less of an issue.
        - When working on the Nat Comms. paper, I mistakenly believed that this
          VCM config included stray light data without correction. However, I
          was wrong. No stray light data is included in this VCM config.

        See https://eogdata.mines.edu/products/vnl/#monthly.

    We don't filter by geometry because DMSP and VIIRS images on Google Earth
    Engine are global images (i.e., not tiled). Filtering is pointless.

    Args
    - year: int, start year of survey

    Returns: ee.Image, contains a single band named 'NIGHTLIGHTS'
    '''
    if 1996 <= year <= 2011:
        img_col_id = 'NOAA/DMSP-OLS/CALIBRATED_LIGHTS_V4/'
        for img_id, v in DMSP_IMGS.items():
            if v['start'] <= year <= v['end']:
                break
        img = ee.Image(img_col_id + img_id)
        img = img.select(['avg_vis'], ['NIGHTLIGHTS'])
        if 'slope' in v:
            img = img.multiply(v['slope']).add(v['bias'])

    else:
        start_date, end_date = surveyyear_to_range(year)
        img = (
            ee.ImageCollection('NOAA/VIIRS/DNB/MONTHLY_V1/VCMCFG')
            .filterDate(start_date, end_date)
            .select(['avg_rad'], ['NIGHTLIGHTS'])
            .median()
        )

    img = img.clamp(0, 1e9)  # upper limit is some arbitrary large number
    return img


def tfexporter(collection: ee.FeatureCollection, export: str, prefix: str,
               fname: str, selectors: ee.List | None = None,
               dropselectors: ee.List | None = None,
               bucket: str | None = None) -> ee.batch.Task:
    '''Creates and starts a task to export a ee.FeatureCollection to a TFRecord
    file in Google Drive or Google Cloud Storage (GCS).

    GCS:   gs://bucket/prefix/fname.tfrecord
    Drive: prefix/fname.tfrecord

    Args
    - collection: ee.FeatureCollection
    - export: str, 'drive' for Drive, 'gcs' for GCS
    - prefix: str, folder name in Drive or GCS to export to, no trailing '/'
    - fname: str, filename
    - selectors: None or ee.List of str, names of properties to include in
        output, set to None to include all properties
    - dropselectors: None or ee.List of str, names of properties to exclude
    - bucket: None or str, name of GCS bucket, only used if export=='gcs'

    Returns
    - task: ee.batch.Task
    '''
    if dropselectors is not None:
        if selectors is None:
            selectors = collection.first().propertyNames()

        selectors = selectors.removeAll(dropselectors)

    if export == 'gcs':
        task = ee.batch.Export.table.toCloudStorage(
            collection=collection,
            description=fname,
            bucket=bucket,
            fileNamePrefix=f'{prefix}/{fname}',
            fileFormat='TFRecord',
            selectors=selectors)

    elif export == 'drive':
        task = ee.batch.Export.table.toDrive(
            collection=collection,
            description=fname,
            folder=prefix,
            fileNamePrefix=fname,
            fileFormat='TFRecord',
            selectors=selectors)

    else:
        raise ValueError(f'export "{export}" is not one of ["gcs", "drive"]')

    task.start()
    return task


def sample_patch(point: ee.Feature, patches_array: ee.Image,
                 scale: float) -> ee.Feature:
    '''Extracts an image patch at a specific point.

    Args
    - point: ee.Feature
    - patches_array: ee.Image, Array Image
    - scale: int or float, scale in meters of the projection to sample in

    Returns: ee.Feature, 1 property per band from the input image
    '''
    arrays_samples = patches_array.sample(
        region=point.geometry(),
        scale=scale,
        projection='EPSG:3857',
        factor=None,
        numPixels=None,
        dropNulls=False,
        tileScale=12)
    return arrays_samples.first().copyProperties(point)


def get_array_patches(img: ee.Image,
                      scale: float,
                      ksize: float,
                      points: ee.FeatureCollection,
                      export: str,
                      prefix: str,
                      fname: str,
                      selectors: ee.List | None = None,
                      dropselectors: ee.List | None = None,
                      bucket: str | None = None
                      ) -> ee.batch.Task:
    '''Creates and starts a task to export square image patches in TFRecord
    format to Google Drive or Google Cloud Storage (GCS). The image patches
    are sampled from the given ee.Image at specific coordinates.

    Args
    - img: ee.Image, image covering the entire region of interest
    - scale: int or float, scale in meters of the projection to sample in
    - ksize: int or float, radius of square image patch
    - points: ee.FeatureCollection, coordinates from which to sample patches
    - export: str, 'drive' for Google Drive, 'gcs' for GCS
    - prefix: str, folder name in Drive or GCS to export to, no trailing '/'
    - fname: str, filename for export
    - selectors: None or ee.List, names of properties to include in output,
        set to None to include all properties
    - dropselectors: None or ee.List, names of properties to exclude
    - bucket: None or str, name of GCS bucket, only used if export=='gcs'

    Returns: ee.batch.Task
    '''
    kern = ee.Kernel.square(radius=ksize, units='pixels')
    patches_array = img.neighborhoodToArray(kern)

    # ee.Image.sampleRegions() does not cut it for larger collections,
    # using mapped sample instead
    samples = points.map(lambda pt: sample_patch(pt, patches_array, scale))

    # export to a TFRecord file which can be loaded directly in TensorFlow
    return tfexporter(collection=samples, export=export, prefix=prefix,
                      fname=fname, selectors=selectors,
                      dropselectors=dropselectors, bucket=bucket)


def wait_on_tasks(tasks: Mapping[Any, ee.batch.Task],
                  show_probar: bool = True,
                  poll_interval: int = 20,
                  ) -> None:
    '''Displays a progress bar of task progress.

    Args
    - tasks: dict, maps task ID to a ee.batch.Task
    - show_progbar: bool, whether to display progress bar
    - poll_interval: int, # of seconds between each refresh
    '''
    remaining_tasks = list(tasks.keys())
    done_states = {ee.batch.Task.State.COMPLETED,
                   ee.batch.Task.State.FAILED,
                   ee.batch.Task.State.CANCEL_REQUESTED,
                   ee.batch.Task.State.CANCELLED}

    progbar = tqdm(total=len(remaining_tasks))
    while len(remaining_tasks) > 0:
        new_remaining_tasks = []
        for taskID in remaining_tasks:
            status = tasks[taskID].status()
            state = status['state']

            if state in done_states:
                progbar.update(1)

                if state == ee.batch.Task.State.FAILED:
                    state = (state, status['error_message'])
                elapsed_ms = status['update_timestamp_ms'] - status['creation_timestamp_ms']
                elapsed_min = int((elapsed_ms / 1000) / 60)
                progbar.write(f'Task {taskID} finished in {elapsed_min} min with state: {state}')
            else:
                new_remaining_tasks.append(taskID)
        remaining_tasks = new_remaining_tasks
        time.sleep(poll_interval)
    progbar.close()


class LandsatSR:
    def __init__(self, start_date: str, end_date: str,
                 filterpoly: ee.Geometry | None = None) -> None:
        '''
        Args
        - start_date: str, string representation of start date
        - end_date: str, string representation of end date
        - filterpoly: ee.Geometry
        '''
        self.filterpoly = filterpoly
        self.start = start_date
        self.end = end_date

        L57_SR_orig_names = [
            'B1',   'B2',    'B3',  'B4',  'B5',    'B7',    'B6',    'pixel_qa']
        L8_SR_orig_names = [
            'B2',   'B3',    'B4',  'B5',  'B6',    'B7',    'B10',   'pixel_qa']
        new_names = [
            'BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2', 'TEMP1', 'pixel_qa']

        self.l8 = (
            self.init_coll('LANDSAT/LC08/C01/T1_SR')
            .select(L8_SR_orig_names, new_names)
            .map(rescale_l8)
        )
        self.l7 = (
            self.init_coll('LANDSAT/LE07/C01/T1_SR')
            .select(L57_SR_orig_names, new_names)
            .map(rescale_l57)
        )
        self.l5 = (
            self.init_coll('LANDSAT/LT05/C01/T1_SR')
            .select(L57_SR_orig_names, new_names)
            .map(rescale_l57)
        )
        self.merged = self.l5.merge(self.l7).merge(self.l8).sort('system:time_start')

    def init_coll(self, name: str) -> ee.ImageCollection:
        '''
        Creates a ee.ImageCollection containing images of desired points
        between the desired start and end dates.

        Args
        - name: str, name of collection

        Returns: ee.ImageCollection
        '''
        imgcol = ee.ImageCollection(name).filterDate(self.start, self.end)
        if self.filterpoly is not None:
            imgcol = imgcol.filterBounds(self.filterpoly)
        return imgcol


def rescale_l8(img: ee.Image) -> ee.Image:
    '''Rescales the bands of a Landsat 8 surface reflectance (SR) image.

    See: https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC08_C01_T1_SR

    Name       Scale Factor Description
    B1         0.0001       Band 1 (Ultra Blue) surface reflectance, 0.435-0.451 um
    B2         0.0001       Band 2 (Blue) surface reflectance, 0.452-0.512 um
    B3         0.0001       Band 3 (Green) surface reflectance, 0.533-0.590 um
    B4         0.0001       Band 4 (Red) surface reflectance, 0.636-0.673 um
    B5         0.0001       Band 5 (Near Infrared) surface reflectance, 0.851-0.879 um
    B6         0.0001       Band 6 (Shortwave Infrared 1) surface reflectance, 1.566-1.651 um
    B7         0.0001       Band 7 (Shortwave Infrared 2) surface reflectance, 2.107-2.294 um
    B10        0.1          Band 10 brightness temperature (Kelvin), 10.60-11.19 um
    B11        0.1          Band 11 brightness temperature (Kelvin), 11.50-12.51 um
    sr_aerosol              Aerosol attributes, see Aerosol QA table
    pixel_qa                Pixel quality attributes, see Pixel QA table
    radsat_qa               Radiometric saturation QA, see Radsat QA table

    Args
    - img: ee.Image, Landsat 8 image, with bands
        ['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2', 'TEMP1', 'pixel_qa']

    Returns
    - img: ee.Image, with bands rescaled
    '''
    opt = img.select(['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2'])
    therm = img.select('TEMP1')
    qa = img.select('pixel_qa')

    # for optical (opt) bands:
    # - range: -20,000 - 16,000
    # - valid range: 0 - 10,000
    # - fill value: -9,999
    # - saturate value: 20,000

    # We mask out negative values, while clamping values above 10,000. If a
    # pixel is still masked out after median compositing, then it is assigned
    # a default value of 0 by ee.Image.neighborhoodToArray(). We assume that
    # pixels originally with negative values are more likely to be truly "0"
    # than a saturated pixel above 10,000.
    opt = opt.updateMask(opt.gte(0)).clamp(0, 10_000)

    opt = opt.multiply(0.0001)
    therm = therm.multiply(0.1)

    scaled = ee.Image.cat([opt, therm, qa]).copyProperties(img)
    # system properties are not copied
    scaled = scaled.set('system:time_start', img.get('system:time_start'))
    return scaled


def rescale_l57(img: ee.Image) -> ee.Image:
    '''Rescales the bands of a Landsat 5/7 surface reflectance (SR) image.

    See: https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LT05_C01_T1_SR
         https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LE07_C01_T1_SR

    Name             Scale Factor Description
    B1               0.0001       Band 1 (blue) surface reflectance, 0.45-0.52 um
    B2               0.0001       Band 2 (green) surface reflectance, 0.52-0.60 um
    B3               0.0001       Band 3 (red) surface reflectance, 0.63-0.69 um
    B4               0.0001       Band 4 (near infrared) surface reflectance, 0.77-0.90 um
    B5               0.0001       Band 5 (shortwave infrared 1) surface reflectance, 1.55-1.75 um
    B6               0.1          Band 6 brightness temperature (Kelvin), 10.40-12.50 um
    B7               0.0001       Band 7 (shortwave infrared 2) surface reflectance, 2.08-2.35 um
    sr_atmos_opacity 0.001        Atmospheric opacity; < 0.1 = clear; 0.1 - 0.3 = average; > 0.3 = hazy
    sr_cloud_qa                   Cloud quality attributes, see SR Cloud QA table. Note:
                                      pixel_qa is likely to present more accurate results
                                      than sr_cloud_qa for cloud masking. See page 14 in
                                      the LEDAPS product guide.
    pixel_qa                      Pixel quality attributes generated from the CFMASK algorithm,
                                      see Pixel QA table
    radsat_qa                     Radiometric saturation QA, see Radiometric Saturation QA table

    Args
    - img: ee.Image, Landsat 5/7 image, with bands
        ['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2', 'TEMP1', 'pixel_qa']

    Returns
    - img: ee.Image, with bands rescaled
    '''
    opt = img.select(['BLUE', 'GREEN', 'RED', 'NIR', 'SWIR1', 'SWIR2'])
    therm = img.select('TEMP1')
    qa = img.select('pixel_qa')

    # for optical (opt) bands:
    # - range: -20,000 - 16,000
    # - valid range: 0 - 10,000
    # - fill value: -9,999
    # - saturate value: 20,000

    # We mask out negative values, while clamping values above 10,000. If a
    # pixel is still masked out after median compositing, then it is assigned
    # a default value of 0 by ee.Image.neighborhoodToArray(). We assume that
    # pixels originally with negative values are more likely to be truly "0"
    # than a saturated pixel above 10,000.
    opt = opt.updateMask(opt.gte(0)).clamp(0, 10_000)

    opt = opt.multiply(0.0001)
    therm = therm.multiply(0.1)

    scaled = ee.Image.cat([opt, therm, qa]).copyProperties(img)
    # system properties are not copied
    scaled = scaled.set('system:time_start', img.get('system:time_start'))
    return scaled
