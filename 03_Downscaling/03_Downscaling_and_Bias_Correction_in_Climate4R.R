### Climate4R libraries
library(loadeR)
library(transformeR)
library(visualizeR)
library(downscaleR)
library(climate4R.value)

### Other libraries
library(RColorBrewer)
library(magrittr)

### Predictor variables
vars <- c("z@850", # geopotential 850 hPa
          "ta@850", "ta@700", "ta@500", # air temperature at 500, 700, 850 hPa
          "hus@700", # specific humidity at 700 hPa
          "va@850", # meridional wind velocity at 850 hPa
          "ua@850") # zonal wind velocity at 850 hPa

### Nº of closest predictor gridpoints
n <- 1

### Statistical model
method <- "GLM"
family <- gaussian(link = "identity")


### Folds
years <- 1980:2000
folds <- list(1980:1987,
              1988:1994,
              1995:2000)

### Latitude longitude boundaries
lonLim = c(-8,2)
latLim = c(36,44)

### Remember to type ?UDG.datasets() to list the available datasets in UDG
di <- dataInventory('ECMWF_ERA-Interim-ESD')

C4R.vocabulary()

grid_x <- lapply(vars, FUN = function(var) {
  loadGridData(dataset = 'ECMWF_ERA-Interim-ESD', 
               var = var,
               years = years,
               lonLim = lonLim,
               latLim = latLim
              )    
}) %>% makeMultiGrid()

### alternatively use readRDS() to load the rds files (e.g., grid_x <- readRDS("path_to_grid_x__file"))

### Subset the air temperature at 850 hPa
grid_x_ta850 <- subsetGrid(grid_x, 
                           var = "ta@850")

### Define the color palette
color_palette <- colorRampPalette(brewer.pal(n = 9, "Reds"))

### Display the spatial map
spatialPlot(climatology(grid_x_ta850), 
            backdrop.theme = "coastline",
            at = seq(6, 12, 0.25),
            set.min = 6,
            set.max = 12,
            col.regions = color_palette,
            main = 'Climatology of the air temperature at 850 hPa (1980-2000)'
            )

### To free memory
rm(grid_x_ta850)

str(grid_x)

predictand_path_to_file <- "./VALUE_europe.zip"
download.file(
    "http://www.value-cost.eu/sites/default/files/VALUE_ECA_86_v2.zip",
    predictand_path_to_file
)

y <- loadStationData(dataset = predictand_path_to_file, 
                     var = "tmean",
                     years = years,
                     lonLim = lonLim,
                     latLim = latLim
)  

str(y)

y$Metadata$name

### Display the spatial map
spatialPlot(climatology(y), 
            xlim = c(-10,10),
            ylim = c(34,48),
            color.theme = "OrRd",
            cuts = seq(2,16,1),
            set.min = 2,
            set.max = 16,
            pch = 20,
            backdrop.theme = "coastline",
            main = 'Climatology of the air temperature at 850 hPa (1980:2000)'
            )

pred_glm1 <- downscaleCV(grid_x,
                         y,
                         folds = folds, 
                         scaleGrid.args = list(type = "standardize"),
                         method = method, 
                         family = family,
                         prepareData.args = list("local.predictors" = list(vars = getVarNames(grid_x), 
                                                                           n = n)))

### Explore the prediction climate4R object
str(pred_glm1)

### ?show.measures()
rmse <- valueMeasure(y, pred_glm1, measure.code = "ts.RMSE")$Measure
rmse_averaged <- mean(rmse$Data, na.rm = TRUE) 

### Display the spatial RMSE field
spatialPlot(rmse, 
            xlim = c(-10,10),
            ylim = c(34,48),
            color.theme = "OrRd",
            cuts = seq(1,2.75,0.125),
            set.min = 1,
            set.max = 2.75,
            backdrop.theme = "coastline",
            main = sprintf('RMSE of the GLM1 model: %s (ºC)', round(rmse_averaged, digits = 2))
            )





### To free memory...
rm(rmse, rmse_averaged, pred_glm1)
gc()

### NOTE: For computational efficiency we only work with these two predictor variables
vars_reduced <- c("z@850", # geopotential 850 hPa
                  "ta@850") # air temperature 850 hPa


### NOTE: For computational efficiency we only work with 10-year temporal period
years_hist <- 1990:2000
years_rcp85 <- 2090:2100

### Labels EC-Earth in UDG
### remember ?UDG.datasets() for UDG labels
label_gcm_hist <- 'CMIP5-subset_EC-EARTH_r12i1p1_historical'
label_gcm_rcp85 <- 'CMIP5-subset_EC-EARTH_r12i1p1_rcp85'

### Loading the historical scenario (1990:2000)
grid_hist <- lapply(vars_reduced, FUN = function(var) {
    loadGridData(dataset = label_gcm_hist, 
                 var = var,
                 years = years_hist, 
                 lonLim = lonLim, 
                 latLim = latLim,
                ) %>% interpGrid(getGrid(grid_x)) # We interpolate the fields to match ERA-Interim spatial resolution  
}) %>% makeMultiGrid()

### Loading the RCP8.5 scenario (2090:2100)
grid_rcp85 <- lapply(vars_reduced, FUN = function(var) {
    loadGridData(dataset = label_gcm_rcp85, 
                 var = var,
                 years = years_rcp85, 
                 lonLim = lonLim, 
                 latLim = latLim,
                ) %>% interpGrid(getGrid(grid_x)) # We interpolate the fields to match ERA-Interim spatial resolution
}) %>% makeMultiGrid()

### alternatively use readRDS() to load the rds files (e.g., grid_hist <- readRDS("path_to_file"))

### Parameters
bias_correction_type <- "center"
time.frame = 'monthly'

### Since we are working with a reduced predictor variable subset we call subsetGrid...
grid_x_2 <- subsetGrid(grid_x, var = vars_reduced)
rm(grid_x)

### Bias-correction historical scenario
grid_hist_bc <- scaleGrid(grid = grid_hist, 
                          base = grid_hist, 
                          ref = subsetGrid(grid_x_2, years = years_hist), 
                          type = bias_correction_type,
                          time.frame = time.frame)

### Scaling the RCP8.5 scenario
grid_rcp85_bc <- scaleGrid(grid = grid_rcp85, 
                           base = grid_hist,
                           ref = subsetGrid(grid_x_2, years = years_hist),
                           type = bias_correction_type,
                           time.frame = time.frame)

### Parameters
standardization_type <- "standardize"

### Scaling the historical scenario
grid_hist_scaled <- scaleGrid(grid = grid_hist_bc, 
                              base = grid_x_2, 
                              type = standardization_type)

### Scaling the RCP8.5 scenario
grid_rcp85_scaled <- scaleGrid(grid = grid_rcp85_bc, 
                               base = grid_x_2, 
                               type = standardization_type)

### To free memory
rm(grid_hist, grid_hist_bc, grid_rcp85, grid_rcp85_bc)
gc()

grid_x_2_scaled <- scaleGrid(grid_x_2, type = "standardize")

grid_xy <- prepareData(x = grid_x_2_scaled,
                       y = y,
                       local.predictors = list(vars = vars_reduced, 
                                               n = n)
           )

model <- downscaleTrain(grid_xy, 
                        method = method, 
                        family = family)

### Prepare input data to downscale the historical scenario
grid_hist_scaled_input <- prepareNewData(newdata = grid_hist_scaled,
                                         data.structure = grid_xy)

### Prepare input data to downscale the RCP8.5 scenario
grid_rcp85_scaled_input <- prepareNewData(newdata = grid_rcp85_scaled,
                                          data.structure = grid_xy)

### To free memory
rm(grid_x_2, grid_hist_scaled, grid_rcp85_scaled, grid_xy)
gc()

### Downscale the historical scenario
pred_hist <- downscalePredict(newdata = grid_hist_scaled_input, 
                              model = model)

### Downscale the RCP8.5 scenario
pred_rcp85 <- downscalePredict(newdata = grid_rcp85_scaled_input, 
                               model = model)

str(y$Data)
str(pred_hist$Data)
str(pred_rcp85$Data)

temporalPlot("Observations" = y, 
             "Historical" = pred_hist,
             "RCP8.5" = pred_rcp85,
             xyplot.custom = list(main = 'Temporal serie of air surface temperarure (ºC)',
                                  ylab = "", xlab = ""))

aggr.y.fun <- list(FUN = "mean", na.rm = TRUE)
temporalPlot("Observations" = aggregateGrid(y, aggr.y = aggr.y.fun), 
             "Historical" = aggregateGrid(pred_hist, aggr.y = aggr.y.fun),
             "RCP8.5" = aggregateGrid(pred_rcp85, aggr.y = aggr.y.fun),
             xyplot.custom = list(main = 'Yearly Temporal serie of air surface temperarure (ºC)',
                                  ylab = "", xlab = ""))






biasCorrection_var = 'pr'
working_with_precipitation <- "TRUE"
biasCorrection_method <- "eqm"
wet.threshold <- 1

pr_gcm_hist <- loadGridData(dataset = label_gcm_hist, 
                            var = biasCorrection_var,
                            years = years_hist, 
                            lonLim = lonLim, 
                            latLim = latLim
                            )  

pr_gcm_rcp85 <- loadGridData(dataset = label_gcm_rcp85, 
                             var = biasCorrection_var,
                             years = years_rcp85, 
                             lonLim = lonLim, 
                             latLim = latLim
                             )  

### alternatively use readRDS() to load the rds files (e.g., pr_gcm_hist <- readRDS("path_to_file"))

pr_value <- loadStationData(dataset = predictand_path_to_file, 
                            var = "precip",
                            years = years_hist,
                            lonLim = lonLim,
                            latLim = latLim
) %>% binaryGrid(condition = "GE", threshold = wet.threshold, partial = TRUE)

### Historical scenario
eqmh <- biasCorrection(y = pr_value, 
                       x = pr_gcm_hist,
                       precipitation = working_with_precipitation,
                       extrapolation = "constant",
                       method = biasCorrection_method,
                       wet.threshold = wet.threshold)

### RCP8.5 scenario
eqmf <- biasCorrection(newdata = pr_gcm_rcp85,
                       y = pr_value, 
                       x = pr_gcm_hist,
                       precipitation = working_with_precipitation,
                       extrapolation = "constant",
                       method = biasCorrection_method,
                       wet.threshold = wet.threshold)

subset_rainy_days <- function(grid, threshold = 1) {
    ind <- which(grid$Data >= threshold) 
    grid_rain <- subsetDimension(grid, 
                                 dimension = "time",                                    
                                 indices = ind)
    return(grid_rain)
}

### Display the distribution for ***
### We work only with one station
num_station <- 1
station_id <- pr_value$Metadata$station_id[num_station]

pr_value_one <- subsetGrid(pr_value, station.id = station_id) %>%
    subset_rainy_days()

coords_station_id <- list("x" = pr_value$xyCoords$x[num_station], "y" = pr_value$xyCoords$y[num_station])
pr_gcm_hist_one <- interpGrid(pr_gcm_hist, new.coordinates = coords_station_id) %>%
    subset_rainy_days()

pr_gcm_rcp85_one <- interpGrid(pr_gcm_rcp85, new.coordinates = coords_station_id) %>%
    subset_rainy_days()

eqm_h_one <- subsetGrid(eqmh, station.id = station_id) %>%
    subset_rainy_days()

eqm_f_one <- subsetGrid(eqmf, station.id = station_id) %>%
    subset_rainy_days()


options(repr.plot.width = 10, repr.plot.height = 10)
qqplot(pr_value_one$Data, pr_gcm_hist_one$Data, 
       pch = 19, col = "purple", main = "Q-Q plot for precipitation", 
       xlim = c(0,100), ylim = c(0,100),
       ylab = "", xlab = "")
eqm_h_one_qq <- qqplot(pr_value_one$Data, eqm_h_one$Data, plot.it = FALSE)
points(eqm_h_one_qq$x, eqm_h_one_qq$y, pch = 19, col = "blue")
pr_gcm_rcp85_one_qq <- qqplot(pr_value_one$Data, pr_gcm_rcp85_one$Data, plot.it = FALSE)
points(pr_gcm_rcp85_one_qq$x, pr_gcm_rcp85_one_qq$y, pch = 19, col = "orange")
eqm_f_one_qq <- qqplot(pr_value_one$Data, eqm_f_one$Data, plot.it = FALSE)
points(eqm_f_one_qq$x, eqm_f_one_qq$y, pch = 19, col = "red")

lines(c(-1, 100), c(-1, 100), col = "black")

legend("bottomright", 
       legend = c("Historical", "Historical (Bias correction)", "RCP8.5", "RCP8.5  (Bias correction)"), 
       col = c("purple", "blue", "orange","red"), 
       lty = c(1,1,1,1))


