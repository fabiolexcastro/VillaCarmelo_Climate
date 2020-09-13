
# Load libraries ----------------------------------------------------------
require(pacman)
pacman::p_load(raster, rgdal, rgeos, stringr, sf, tidyverse, gtools, ccafs)

rm(list = ls())
rappdirs::user_cache_dir('ccafs')

# Functions to use --------------------------------------------------------
download_climate <- function(vr, pr){
  
  # vr <- 'tmax'
  # pr <- '2030s'
  
  vr_nm <- vrs %>% filter(variable == vr) %>% pull(1)
  pr_nm <- prd %>% filter(period == pr) %>% pull(1)
  
  looking <- cc_search(
    file_set = 12, 
    scenario = 10, 
    period = pr_nm, 
    resolution = 1,
    variable = vr_nm, 
    extent = 'region'
  )
  
  looking <- grep('c2_asc.zip', looking, value = TRUE)
  gcms <- str_sub(looking, start = 93, end = nchar(looking) - 10)
  gcms <- str_split(gcms, pattern = '/')
  gcms <- sapply(1:length(gcms), function(k) gcms[[k]][1])
  
  download <- lapply(1:length(looking), function(k){
    
    print(looking[k])
    rstr <- cc_data_fetch(key = looking[k])
    rstr <- cc_data_read(rstr)
    rstr <- raster::crop(rstr, shp) %>% raster::mask(., shp)
    
    dir_output <- paste0('../datos/raster/climate/ipcc/rcp85/', pr, '/', gcms[k])
    ifelse(!dir.exists(dir_output), dir.create(dir_output, recursive = TRUE), 'Directory exist')
    
    Map('writeRaster', x = unstack(rstr), filename = paste0(dir_output, '/', names(rstr), '.tif'), overwrite = TRUE)
    
    rm(rstr)
    rm(dir_output)
    
    cache <- list.files(rappdirs::user_cache_dir('ccafs'), full.names = TRUE)
    map(.x = 1:length(cache), .f = function(k) file.remove(cache[k]))
    cc_cache_delete_all(force = TRUE)
    print(paste0('Done ', looking[k]))
    
  })
  
  print(paste0(' ================================= Done ', vr, ' ', pr, ' ================================'))
  
}

# Load data ---------------------------------------------------------------
shp <- shapefile('../datos/shapefiles/base/Area_estudio.shp')
geo <- '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'
shp <- spTransform(x = shp, CRSobj = geo)

# Labels - options
vrs <- data.frame(
  value = c(3,4,5,2),
  variable = c('tmax', 'tmean', 'tmin', 'prec')
)
prd <- data.frame(
  value = c(4, 6, 7, 9),
  period = c('2030s', '2050s', '2060s', '2070s')
)

# To download the climate data for the future -----------------------------
lapply(1:2, function(i){
  
  lapply(1:4, function(j){
    
    print(paste0(' ----------------------- To starting... ', pull(vrs,2)[j], ' ', pull(prd,2)[i], ' --------------------- '))
    download_climate(vr = pull(vrs, 2)[j], pr = pull(prd, 2)[i])
    print('Done!')
    
  })
  
})




