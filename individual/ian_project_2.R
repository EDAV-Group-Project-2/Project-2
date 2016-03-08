library(ncdf4)
library(ggplot2)
library(devtools)
install_github("vqv/ggbiplot")
library(ggbiplot)

setwd('~/Desktop/Columbia/EDAV/Project2')

ncname <- "NOAA_Daily_phi_500mb"
ncfname <- paste(ncname, ".nc", sep = "")
dname <- "phi" #For variable name phi
ncin <- nc_open(ncfname)

lon <- ncvar_get(ncin, "X")
lat <- ncvar_get(ncin, "Y", verbose = F)
time_var <- ncvar_get(ncin, "T")
tunits <- ncatt_get(ncin, "T", "units")

dmissing_value <- ncatt_get(ncin, dname, "missing_value")
phi.array <- ncvar_get(ncin, dname)
phi.array[phi.array == dmissing_value$value] <- NA


x = rep(0:143 * 2.5 - 180, times=15)
y = rep(0:14 * 2.5 + 35, each=144)
# Take first 
z = phi.array[2161:4320]
df = data.frame(y, x, z)

ggplot(aes(x=x,y=y,fill=z),data=df) + geom_tile()

map.dat <- map_data("world")

ggplot() + geom_polygon(aes(long, lat, group=group), fill="grey65", data=map.dat) +
theme_bw() + theme(axis.text = element_blank(), axis.title=element_blank()) +
geom_point(aes(x=x, y=y, show_guide=TRUE, color=z, size=13), data=df, alpha=.7, na.rm=T) +
scale_color_gradient(low='beige', high='blue')

colnames(df) = c('Lat', 'Lon', 'Phi')
pca = princomp(df, scores=TRUE, cor=TRUE, center=TRUE, scale=TRUE)
summary(pca)
plot(pca)
biplot(pca, expand=1, xlim=c(-0.05, 0.05), ylim=c(-0.05, 0.05)) 
# todo - use ggbiplot. longitude and phi values are more coorelated than lat and phi...?
pca$loadings


####### Woojin method loading floods data
df2 = read.csv('GlobalFloodsRecord.csv', fileEncoding="macroman", stringsAsFactors = FALSE)
# Fix dataset
fix.index = c(2,8,22,30)
colnames(df2)[fix.index] = c("Annual.DFO", "Detailed.Locations", "News", "Notes")
num.cols = c(2,12,13,14,15,17,18,19,20,21)
df2[,num.cols] <- sapply(df2[,num.cols], as.numeric)
df2$X <- NULL

# make centroid x 0 -> 360
df2$Centroid.X = df2$Centroid.X + 180
# format dates (just using begin dates for now)
df2$newDate <- as.Date(df2$Began, "%e-%b-%y")
# turn into days since 1948-01-01
Diff <- function(x) as.numeric(x - as.Date('1945-01-01'))
df2 = transform(df2, numDays = Diff(newDate))

# Take the average of the phi values from days when flooding started
flood_phi_values = c()
for (i in 1:4356) {
  centroid_x = df2$Centroid.X[i]
  centroid_y = df2$Centroid.Y[i]
  lon_index = floor(df2$Centroid.X[i] / 2.5)
  lat_index = floor(df2$Centroid.Y[i] / 2.5)
  if (!is.na(lat_index) && !is.na(lon_index)) {
    if (lat_index > 0 && lat_index < 15) {
      if (!is.na(phi.array[lon_index, lat_index, i])) {
        flood_phi_values[i] = phi.array[lon_index, lat_index, i]
      }
    }
  }
}

# Compare these values to average phi
mean(flood_phi_values, na.rm=TRUE)
mean(df$Phi)
min(df$Phi)
max(df$Phi)



a <- table(df2$Date.Began)


##### Trellis plot for flood counts per year
histogram(~factor(format(df2$newDate,"%b"),
                  levels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")) |
            factor(format(newDate,"%y")), data=df2, layout=(c(3,6)),
          main="Flood Counts by year and month",
          ylab="Flood Count",
          xlab="Year")



##### New Trellis using ggplot
df_ian$year <- format(df_ian$newDate, format="%Y")
df_ian$year <- as.numeric(df_ian$year)
df_ian$month <- format(df_ian$newDate, format="%b")
df_ian$monthInt <- format(df_ian$newDate, format="%m")
df_ian$monthInt <- as.numeric(df_ian$monthInt)
df_ian$month <- as.factor(df_ian$month)

# df_ian$a = factor(format(df_ian$newDate,"%b"),
levels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

ggplot(df_ian, aes(month)) +
  geom_freqpoly(stat="count") +
  facet_wrap(~ year, nrow=11, ncol=3) +
  xlab("My x label")

levels(df_ian$monthInt) <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
ggplot(df_ian, aes(monthInt)) + stat_bin() + facet_grid(year ~ .)

