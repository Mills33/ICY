FROM rocker/r-base:latest

MAINTAINER Camilla Ryan "camilla.ryan@earlham.ac.uk"

RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    libxml2 \
    libxml2-dev \
    python3 \
    python3-pip

RUN R -e "install.packages('shiny', repos = 'http://cran.rstudio.com/')"
RUN R -e "install.packages('shinythemes', repos = 'http://cran.rstudio.com/')"
RUN R -e "install.packages('rmarkdown', repos = 'http://cran.rstudio.com/')"
RUN R -e "install.packages('reticulate', repos = 'http://cran.rstudio.com/')"
RUN R -e "install.packages('tinytex')"
RUN R -e "install.packages('ggplot2', repos = 'http://cran.rstudio.com/')"
RUN R -e "install.packages('tibble', repos = 'http://cran.rstudio.com/')"
RUN R -e "install.packages('dplyr', repos = 'http://cran.rstudio.com/')"
RUN R -e "install.packages('kableExtra', repos = 'http://cran.rstudio.com/')"
RUN R -e "install.packages('knitr', repos = 'http://cran.rstudio.com/')"

RUN pip3 install pandas numpy

COPY ICY.Rproj /
#COPY app.R /
COPY ui.R /
COPY server.R /
COPY run.R /
COPY Documents /Documents
COPY ICY.Rmd /
COPY ichooseyou_sep.py /
COPY www /www
COPY Images /Images

#EXPOSE 80

#RUN sudo chown -R shiny:shiny /srv/shiny-server

#COPY shiny-server.conf  /etc/shiny-server/shiny-server.conf
#COPY shiny-server.sh /usr/bin/shiny-server.sh

CMD ["Rscript", "/run.R"]
