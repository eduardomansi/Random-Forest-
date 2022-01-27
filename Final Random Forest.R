library(ggplot2)
library(cowplot)
library(randomForest)

data<-read.csv("spotify_decade.csv")
str(data)
data.ready<-data[,-c(1,2,3)]
str(data.ready)

factor_cols<-c("key","target","mode","Decade","time_signature")
data.ready[factor_cols]<-lapply(data.ready[factor_cols],as.factor)

set.seed(100)
predictors<-data.ready[,-16]
str(predictors)
target<-data.ready$target

model<-randomForest(predictors,target,importance=TRUE)
model
#wanting to try a specific song?
New<-data.frame(danceability=.417,energy=.62,key="5",loudness=-7.73,
                mode="1",speechiness=0.0403,acousticness=0.49,instrumentalness=0,
                liveness=0.0779,valence=0.845,tempo=186,duration_ms=173533,
                time_signature="3",chorus_hit=32.9,sections=9,Decade="1960")
str(New)

predict(model,New)
#if having the different type problem bind and then delete
test<-rbind(predictors[1,], New)
test<-test[-1,]
test
predict(model,test)

#--------------------- Diving into the project ------------------

data<-read.csv("spotify_decade.csv")
str(data)
#we should get rid of the columns that doesn't contribute to our prediction
#goals
data.ready<-data[,-c(1,2,3,20)]
str(data.ready)
factor_cols<-c("key","target","mode","time_signature")
data.ready[factor_cols]<-lapply(data.ready[factor_cols],as.factor)
predictors<-data.ready[,-16]
str(predictors)
target<-data.ready$target
set.seed(100)
model<-randomForest(predictors,target,ntree = 1000)
model
#Lets look for the optimal number of trees looking at the sequence of Out-of-Bag errors
oob.error.data <- data.frame(
  Trees=rep(1:nrow(model$err.rate), times=3),
  Type=rep(c("OOB", "Flop", "Hit"), each=nrow(model$err.rate)),
  Error=c(model$err.rate[,"OOB"], 
          model$err.rate[,"0"], 
          model$err.rate[,"1"]))

ggplot(data=oob.error.data, aes(x=Trees, y=Error)) +
  geom_line(aes(color=Type))
#RESULT-Lets consider 500 trees
#Lets look for the optimal number of variables to consider at each split
oob.values <- vector(length=10)

for(i in 1:10) {
  set.seed(100)
  temp.model <- randomForest(predictors,target, mtry=i, ntree=500)
  oob.values[i] <- temp.model$err.rate[nrow(temp.model$err.rate),1]
}
oob.values
#since 4 is the one that has the less OOB error we will consider mtry to be =4,
#which happens to be the one by default but we were not sure it was optimal
set.seed(100)
model<-randomForest(predictors,target,ntree = 500,mtry=4)
model
#lets check for model improvements by getting rid of old tastes for music which are
#bringing noise to the model. Considering just the last 3 decades was found
#to bring the highest accuracy. Just by running the selected dataset.
#Here it is presented straight to the last 3 decades.
data.ready<-data[,-c(1,2,3)]
factor_cols<-c("key","target","mode","Decade","time_signature")
data.ready[factor_cols]<-lapply(data.ready[factor_cols],as.factor)
predictors.900010<-data.ready[data.ready$Decade==1990|
                                data.ready$Decade==2000|data.ready$Decade==2010,-16]

target.900010<-data.ready[data.ready$Decade==1990|
                            data.ready$Decade==2000|data.ready$Decade==2010,]$target

#-----------Exploring with chosen dataset (last 3 decades)
set.seed(100)
model<-randomForest(predictors.900010,target.900010,ntree = 1000, mtry=4)
model
oob.error.data <- data.frame(
  Trees=rep(1:nrow(model$err.rate), times=3),
  Type=rep(c("OOB", "Flop", "Hit"), each=nrow(model$err.rate)),
  Error=c(model$err.rate[,"OOB"], 
          model$err.rate[,"0"], 
          model$err.rate[,"1"]))

ggplot(data=oob.error.data, aes(x=Trees, y=Error)) +
  geom_line(aes(color=Type))
oob.values <- vector(length=10)

for(i in 1:10) {
  set.seed(100)
  temp.model <- randomForest(predictors.900010,target.900010, mtry=i, ntree=500)
  oob.values[i] <- temp.model$err.rate[nrow(temp.model$err.rate),1]
}
oob.values
a<-data.frame(oob.values)
colnames(a)<-"OOB errors"
a
#This suggests to use 4 variables which was by default but we prove to be the optimal
set.seed(100)
model <- randomForest(predictors.900010,target.900010, mtry=4, ntree=500, importance = TRUE)
model

varImpPlot(model,type=1,main='Permutation Predictors Importance')

