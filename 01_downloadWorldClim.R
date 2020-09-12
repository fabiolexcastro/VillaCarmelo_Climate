do

# Load libraries ----------------------------------------------------------
require(pacman)
pacman::p_load(raster, rgdal, rgeos, stringr, sf, tidyverse, gtools)

g <- gc(reset = T)
rm(list = ls())
options(scipen = 999)

# Functions to use --------------------------------------------------------
download_climate <- function(vr){
  print(vr)
  clm <- raster::getData(name = 'worldclim', var = vr, res = 0.5, lon = crd[1,1], lat = crd[1,2])
  Map('writeRaster', x = unstack(clm), filename = paste0('../datos/raster/climate/worldclim/south/', vr, '_', 1:12, '.tif'))
  print('Done')
}
extract_by_mask <- function(vr){
  
  print(vr)
  
  fl <- grep(vr, fls, value = TRUE)
  rs <- map(.x = fl, .f = raster)
  rs <- map(.x = 1:12, .f = function(k){
    print(k)
    rt <- raster::crop(rs[[k]], shp)
    rt <- raster::mask(rt, shp)
    print('Done')
    return(rt)
  })
  
  Map('writeRaster', x = rs, filename = paste0('../datos/raster/climate/worldclim/villamontes/', vr, '_', 1:12, '.tif'))
  print('Done!')
  
}

# Load data ---------------------------------------------------------------
shp <- shapefile('../datos/shapefiles/base/Area_estudio.shp')
geo <- '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'
vrs <- c('tmax', 'tmean', 'tmin', 'prec')

# Calculating the centroid ------------------------------------------------
shp <- spTransform(x = shp, CRSobj = geo)
crd <- coordinates(shp)

# Download climate data ---------------------------------------------------
lapply(1:length(vrs), function(k) download_climate(vr = vrs[k]))

# Extract by mask ---------------------------------------------------------
fls <- list.files('../datos/raster/climate/worldclim/south', full.names = TRUE, pattern = '.tif$')
fls <- mixedsort(fls)
lapply(1:length(vrs), function(k) extract_by_mask(vr = vrs[k]))


