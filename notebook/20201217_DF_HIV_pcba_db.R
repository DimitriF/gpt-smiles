library(RSQLite)
library(magrittr)
library(reshape2)

conn <- dbConnect(RSQLite::SQLite(), "../perso/smiles_clean.db")

# hiv = read.csv('~/perso/Molecules_Dataset_Collection/latest/HIV.csv')
# pcba = read.csv('~/perso/Molecules_Dataset_Collection/latest/pcba.csv')

str(hiv)
barplot(table(hiv$activity))
barplot(table(hiv$HIV_active))
table(hiv$activity, hiv$HIV_active)


str(pcba, list.len=ncol(pcba))

pcba = pcba[,!colnames(pcba) %in% c('X','mol_id')]

# pcba_info = data.frame()
pcba_info = lapply(colnames(pcba)[seq(ncol(pcba)-1)],
       function(x){
         table(pcba[,x],useNA = 'always')
       }) %>% do.call(rbind,.)
rownames(pcba_info) = colnames(pcba)[seq(ncol(pcba)-1)]

task_kept = rownames(pcba_info[pcba_info[,'1'] > 5000,])

pcba = pcba[,c(task_kept,'smiles')]

set.seed(1)
train = sample(seq(nrow(pcba)),400000)
pcba_train = pcba[train,]
pcba_test = pcba[-train,]

library(reshape2)
long_train <- melt(pcba_train, id.vars = c("smiles"),na.rm = T)
long_test <- melt(pcba_test, id.vars = c("smiles"),na.rm = T)

long_train$id = seq(nrow(long_train))
long_test$id = seq(nrow(long_test))

dbWriteTable(conn,"pcba_train", long_train, append = TRUE)
dbWriteTable(conn,"pcba_test", long_test, append = TRUE)

dbExecute(conn, 'CREATE UNIQUE INDEX id_pcba_test ON pcba_test (id);')
dbExecute(conn, 'CREATE UNIQUE INDEX id_pcba_train ON pcba_train (id);')


dbDisconnect(conn)
