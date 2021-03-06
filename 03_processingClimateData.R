

# Load libraries ----------------------------------------------------------
require(pacman)
pacman::p_load(raster, rgdal, rgeos, stringr, sf, tidyverse, gtools, foreach, parallel, doSNOW)

g <- gc(reset = TRUE)
rm(list = ls())

# Functions to use --------------------------------------------------------
calc_difference <- function(vr, gc, yr){
  
  # vr <- vrs[1]
  # gc <- gcm[1]
  # yr <- '2020_2049'
  
  cat('\tCurrent')
  cr <- grep(vr, crn, value = T)
  cr <- stack(cr)
  
  cat('\tFuture')
  fr <- paste0('../datos/raster/climate/ipcc/rcp85/server/', yr, '/', gc) 
  fr <- list.files(fr, full.names = T) 
  vr <- paste0(vr, '_', 1:12, '$')
  fr <- grep(paste0(vr, collapse = '|'), fr, value = T)
  fr <- mixedsort(fr)
  fr <- stack(fr)
  
  cat('\tResample')
  cr <- raster::resample(cr, fr, method = 'ngb')
  
  cat('\tDifference')
  df <- fr - cr
  pr <- df / cr * 100
  
  cat('\tTo write')
  Map('writeRaster', x = unstack(df), filename = paste0('../datos/output/climate/difference/', yr, '/', gc, '_', gsub('\\$', '', vr), '_dfr.tif'), overwrite = TRUE)
  Map('writeRaster', x = unstack(pr), filename = paste0('../datos/output/climate/difference/', yr, '/', gc, '_', gsub('\\$', '', vr), '_prc.tif'), overwrite = TRUE)
  
}

# Load data ---------------------------------------------------------------
shp <- shapefile('../datos/shapefiles/base/AOP/Area_estudio.shp')

# Project the shapefile
shp <- spTransform(x = shp, CRSobj = '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs')

# Read climate data -------------------------------------------------------
vrs <- c('prec', 'tmax', 'tmean', 'tmin')

# Current 
crn <- list.files('../datos/raster/climate/worldclim/villamontes', full.names = T, pattern = '.tif$') %>% 
  mixedsort()
gcm <- list.files('../datos/raster/climate/ipcc/rcp85/server/2020_2049')

# To calculating the difference -------------------------------------------

# 2030s
cl <- makeCluster(6)
registerDoSNOW(cl)

foreach(i = 1:length(gcm), .verbose = TRUE) %dopar% {
  
  require(pacman)
  pacman::p_load(raster, rgdal, rgeos, stringr, sf, tidyverse, gtools, foreach, parallel, doSNOW)
  
  foreach(j = 1:length(vrs)) %do% {
    
    calc_difference(vr = vrs[j], gc = gcm[i], yr = '2020_2049')
    
  }
  
}

stopCluster(cl)

# 2050s
cl <- makeCluster(8)
registerDoSNOW(cl)

foreach(i = 1:length(gcm), .verbose = TRUE) %dopar% {
  
  require(pacman)
  pacman::p_load(raster, rgdal, rgeos, stringr, sf, tidyverse, gtools, foreach, parallel, doSNOW)
  
  foreach(j = 1:length(vrs)) %do% {
    
    calc_difference(vr = vrs[j], gc = gcm[i], yr = '2040_2069')
    
  }
  
}

stopCluster(cl)


# Calculating the averages ------------------------------------------------
fls <- list.files('../datos/output/climate/difference/2040_2069', full.names = TRUE, pattern = '.tif$') %>% 
  grep('tmax_', ., value = TRUE) %>% 
  grep('dfr.tif', ., value = TRUE) %>% 
  mixedsort()
rst <- lapply(1:33, function(k){
  
  cat(k)
  fle <- grep(paste0(gcm[k], '_t'), fls, value = T)
  rst <- stack(fle)
  avg <- mean(rst)
  cat('Done')
  return(avg)
  
})

avg <- mean(stack(rst))
avg <- avg / 10
avg <- raster::crop(avg, shp) %>% raster::mask(., shp)

shp@data$gid <- 1:2
zne <- rasterize(shp, avg[[1]], field = 'gid')
znl <- raster::zonal(avg, zne, fun = 'mean')
znl <- as.data.frame(znl) %>% mutate(mean = round(mean, 2))

writeRaster(avg, '../datos/output/climate/difference/tmax_2040_2069.tif', overwrite = TRUE)


