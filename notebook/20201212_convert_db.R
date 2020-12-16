library(RSQLite)

conn <- dbConnect(RSQLite::SQLite(), "../perso/smiles_clean.db")
set.seed(1)

n_train = 0
n_test = 0
MolFormulas = data.frame()

for(k in dir('~/perso/process_full/')){
  print(k)
  data = read.csv(paste0('~/perso/process_full/',k))
  colnames(data)[1] = 'id'
  data = data[data$orga == 'True',]
  MolF = unique(data$MolFormula)
  MolF_new = setdiff(MolF, MolFormulas$MolFormulas)
  Molf_new_train = sample(c(T,F),length(MolF_new),prob = c(0.9975,0.0025), replace = T)
  logp_new = sapply(MolF_new,
                    function(x){
                      sample(data$logp[data$MolFormula == x],1)
                    })
  if(length(MolF_new) != 0){
    MolFormulas = rbind(MolFormulas, 
                        data.frame(MolFormulas = MolF_new, train = Molf_new_train, logp = logp_new))
  }
  train = data$MolFormula %in% MolFormulas$MolFormulas[MolFormulas$train]
  data_train = data[train,]
  data_test = data[!train,]
  data_train[,1] = seq(nrow(data_train)) + n_train
  n_train = n_train + nrow(data_train)
  if(nrow(data_test) != 0){
    data_test[,1] = seq(nrow(data_test)) + n_test
    n_test = n_test + nrow(data_test)
  }
  dbWriteTable(conn,"smiles_train", data_train, append = TRUE)
  dbWriteTable(conn,"smiles_test", data_test, append = TRUE)
  print(length(MolF_new))
  print(nrow(data_test))
}
dbWriteTable(conn,"MolFormulas", MolFormulas, append = TRUE)


dbExecute(conn, 'CREATE UNIQUE INDEX id_test ON smiles_test (id);')
dbExecute(conn, 'CREATE UNIQUE INDEX id_train ON smiles_train (id);')

dbDisconnect(conn)
