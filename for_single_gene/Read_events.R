#!/usr/bin/env Rscript
suppressMessages(library(optparse))

#for command line parsing
args = commandArgs(trailingOnly=TRUE)
option_list = list(
  make_option(c("-f", "--file"), type="character", default=NULL,
              help="Event file name from Nanopolish", metavar="character"),
        make_option(c("-o", "--out"), type="character", default="out.txt",
              help="output file name", metavar="character")
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

if (is.null(opt$file) | is.null(opt$out)){
  print_help(opt_parser)
  stop("Input file and output names must be supplied.", call.=FALSE)
}

suppressMessages(library(dplyr))
suppressMessages(library(Rcpp))
suppressMessages(library(pracma))
suppressMessages(library(data.table))

#loading c++ script
suppressMessages(library(tidyverse))
getCurrentFileLocation <-  function()
{
    this_file <- commandArgs() %>% 
    tibble::enframe(name = NULL) %>%
    tidyr::separate(col=value, into=c("key", "value"), sep="=", fill='right') %>%
    dplyr::filter(key == "--file") %>%
    dplyr::pull(value)
    if (length(this_file)==0)
    {
      this_file <- rstudioapi::getSourceEditorContext()$path
    }
    return(dirname(this_file))
}
Rcpp::sourceCpp(paste(getCurrentFileLocation(), "/for_r.cpp", sep=""))

#loading of event files
dat= fread(paste(opt$file))
print("Done loading")

#combine events of same strands and positions
dat.com= dat %>% 
		  mutate(count=round(3012*event_length)) %>% 
		  group_by(contig,read_name,position) %>% 
		  summarise(event_stdv=sd_combine(event_stdv,event_level_mean,count),
					event_level_mean=mean_combine(event_level_mean,count),
					count=sum(count),reference_kmer=unique(reference_kmer))  %>% 
		  ungroup() %>%
		  mutate(event_stdv=ifelse(event_stdv==0,0.01,event_stdv))

#saving the results
saveRDS(dat.com,file=paste(opt$out,".RData", sep=""))

print("script ran successfully")
