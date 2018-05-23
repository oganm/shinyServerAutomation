library(git2r)
library(stringr)
library(magrittr)
library(glue)

# path to shiny apps read by the shiny server
shinyApps = '/srv/shiny-server/'

name = 'Ogan Mancarci'

domain = 'http://oganm.com/shiny'

# a different path where git repos will be stored
gitRepoPath = 'appRepos'

# a named character vector. names are how the app will appear the shiny server, the path is
# username/reponame/{path to app within the repo}. last bit is optional
githubApps = c(interactiveSheet = 'oganm/import5eChar/inst/app',
               printSheetApp = 'oganm/printSheetApp',
               initTrack = 'oganm/initTrack',
               vasco = 'hackseq/vasco')


dir.create(gitRepoPath, showWarnings = FALSE)

for(i in seq_along(githubApps)){
    app = githubApps[i]
    gitRepo = app %>% strsplit('/') %>% {.[[1]][1:2]} %>% paste(collapse= '/')
    
    if(length(app %>% strsplit('/') %>% {.[[1]]}) > 2){
        withinRepoPath =  app %>% strsplit('/') %>% {.[[1]][3:length(.[[1]])]} %>% paste(collapse= '/')
    } else{
        withinRepoPath = ''
    }
        
    if(!file.exists(file.path(gitRepoPath,gitRepo))){
        git2r::clone(url = glue('https://github.com/{gitRepo}.git'),
                     local_path = file.path(gitRepoPath,gitRepo))
    } else{
        repo = git2r::repository(file.path(gitRepoPath,gitRepo))
        message = git2r::pull(repo)
        if(message@up_to_date){
            # if up to date,this means we already did this. don't do a thing
            next()
        }
    }
    # unlink(file.path(shinyApps,names(app)),recursive = TRUE, force = TRUE)

    tmp = tempdir()
    dir.create(file.path(shinyApps,names(app)))
    
    filesToCopy = list.files(file.path(gitRepoPath, gitRepo, withinRepoPath),full.names = TRUE,all.files = TRUE,recursive = TRUE)
    
    
    for (x in filesToCopy){
        file = x
        target = gsub(paste0(file.path(gitRepoPath, gitRepo, withinRepoPath),'/'), '', file,fixed = TRUE)
        targetDir =  file.path(shinyApps,names(app),target)
        
        
        dir.create(dirname(targetDir), recursive = TRUE, showWarnings = FALSE)
        file.copy(from  = file,
                  to = targetDir,
                  recursive = FALSE,
                  overwrite = TRUE)
    }
    system(glue::glue('chmod -R 777 {shQuote(file.path(shinyApps,names(app)))}'))
    
    system2('touch', file.path(shinyApps,names(app),'restart.txt'))
}


rmarkdown::render('index.rmd',params = list(shinyApps = shinyApps,
                                            name = name,
                                            domain = domain))

file.copy('index.html',file.path(shinyApps,'index.html'),overwrite = TRUE)
