if(require(renderthis)==FALSE) remotes::install_github("jhelvy/renderthis", dependencies = TRUE)
if(require(officer) == FALSE) install.packages('officer')

renderthis::to_pdf(from = 'intro_big_data.html',
                   to = 'intro_big_data.pdf',
                   complex_slides = TRUE,
                   partial_slides = TRUE,
                   delay = 2)
