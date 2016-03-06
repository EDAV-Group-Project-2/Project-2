library(ncdf4)
library(chron)
library(RColorBrewer)
library(lattice)
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
df2$newDate <- as.Date(df$Began, "%e-%b-%y")
# turn into days since 1948-01-01
Diff <- function(x) as.numeric(x - as.Date('1945-01-01'))
df2 = transform(df2, NumDays = Diff(newDate))




