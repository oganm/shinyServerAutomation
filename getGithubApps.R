library(git2r)
library(stringr)
library(magrittr)
library(glue)

# path to shiny apps read by the shiny server
shinyApps = '/srv/shiny-server/'

# a different path where git repos will be stored
gitRepoPath = 'appRepos'

# a named character vector. names are how the app will appear the shiny server, the path is
# username/reponame/{path to app within the repo}. last bit is optional
githubApps = c(interactiveSheet = 'oganm/import5eChar/inst/app',
               printSheetApp = 'oganm/printSheetApp')


dir.create('gitRepoPath', showWarnings = FALSE)

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
                     local_path = glue('{gitRepoPath}/{gitRepo}'))
    } else{
        repo = git2r::repository(file.path(gitRepoPath,gitRepo))
        message = git2r::pull(repo)
        if(message@up_to_date){
            # if up to date,this means we already did this. don't do a thing
            next()
        }
    }
    unlink(file.path(shinyApps,names(app)),recursive = TRUE, force = TRUE)

    tmp = tempdir()
    dir.create(file.path(shinyApps,names(app)))
    
    file.copy(from  = file.path(gitRepoPath, gitRepo, withinRepoPath),
              to = tmp,
              recursive = TRUE)
    
    file.rename(from = file.path(tmp,basename(withinRepoPath)),
                to = file.path(tmp,names(app)))
    
    file.rename(from = file.path(tmp,names(app)),
                to = file.path(shinyApps,names(app)))

}