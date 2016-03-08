library(ncdf4)
library(RNetCDF)
library(rworldmap)
gf <- read.csv(file="~/Desktop/Columbia/EDAV/Project2/GlobalFloodsRecord.csv", header=TRUE, sep=",")
flood.month.data = data.frame(Longitude=as.numeric(as.character(gf$Centroid.X)),Latitude=as.numeric(as.character(gf$Centroid.Y)),
                              Magnitude=as.numeric(gf$Magnitude..M...), month=format(as.Date(gf$Began,format='%d-%b-%y'),"%m"))
month=c("01","02","03","04","05","06","07","08","09","10","11","12")
for(i in 1:12){
flood.12.data <- subset(flood.month.data,month=="12")
world_map <- map_data("world")
p <- ggplot() + coord_fixed() +xlab("") + ylab("")
base_world <- p + geom_polygon(data=world_map, aes(x=long, y=lat, group=group),colour="white", fill="grey")+labs(title="World map Flood Magnitude(DEC)")
base_world
map_data <- base_world + geom_point(data=flood.12.data, aes(x=Longitude, y=Latitude,color=-Magnitude),size=2,alpha=I(0.6))
map_data
}
