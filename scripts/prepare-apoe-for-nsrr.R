#-------------------------------------------#
#                                           #
#    Prepare APOE dataset for the NSRR      #
#                                           #
#-------------------------------------------#

# install packages
# install.packages("haven")
# install.packages("dplyr")

# load packages

library(haven)
library(dplyr)

# set version
ver <- "0.2.0"

# import original data
source_pheno <- readxl::read_excel("//rfawin.partners.org/bwh-sleepepi-nsrr-staging/20231018-mignot-apoe/original/ApoE_study_data.xlsx")
source_geno <- readxl::read_excel("//rfawin.partners.org/bwh-sleepepi-nsrr-staging/20231018-mignot-apoe/original/ApoE, ACE and DQ0602 typing.xlsx")

# combine source data
source <- left_join(source_pheno, source_geno, by=c("APOE_ID"), multiple = "first")

# write new variable names
newnames <-   c('apoe_id', 'apoe_edf_date',  'apoe_filename',
                'apoe_edf_label',  'psg_duration',  'tst',   'tib',
                'pct_s1', 'pct_s2',  'pct_s3','pct_rem', 'sleep_efficiency',
                'odi3evtotal',  'sao2_baseline', 'sao2_mean',  'sao2_min',
                'glucose',  'triglycerides',    'ldl', 'hdl',
                'total_choleserol', 'vldl', 'age',  'gender', 'bmi', 'height',
                'weight', 'waist_cm', 'hip_cm', 'neck_cm','sysbp', 'diabp',
                'high_cholesterol', 'htn', 'depression', 'asthma', 'thyroid',
                'diabetes', 'gerd', 'plmindex', 'ess', 'rls_sleep_onset',
                'rls_disturbed_sleep', 'rls_probability', 'rls_phenotype',
                'dx_1st', 'dx_other','dx_2nd', 'dx_3rd','observations',
                'current_med', 'dq0602_genotype', 'apoe_genotype', 
                'ace_genotype')

# view side-by-side to confirm appropriate line up
cbind(colnames(source), newnames)

# overwrite original variable names to new ones
colnames(source) <- newnames

# Make rls_probability into a numeric factor to match the domain
for(i in 1:length(source$rls_probability)){
  if(!is.na(source$rls_probability[i])){
  if(source$rls_probability[i] =="BLANK"){source$rls_probability[i] <- NA }
  if(source$rls_probability[i] =="Control"){source$rls_probability[i] <- 1 }
  if(source$rls_probability[i] =="Probable"){source$rls_probability[i] <- 2 }
  if(source$rls_probability[i] =="Possible"){source$rls_probability[i] <- 3 }
  if(source$rls_probability[i] =="Definite"){source$rls_probability[i] <- 4 }}}

# fix "blank" or "na" to be set missing:
vars <- c("rls_disturbed_sleep", "rls_phenotype", "rls_probability", "rls_sleep_onset")
for(i in 1:length(source$rls_disturbed_sleep)){
  for(j in vars){
    if(!is.na(source[i,j])){
      if(source[i,j]%in%c("BLANK", "NA")){
        source[i,j] <- NA }}}}

# create a per/h version of odi3ev variable
source$odi3evindex <- source$odi3evtotal/source$tst

# add visit variable for NSRR display
source$visit <- 1

#fix ds_1st has 3 versions of other, and 2 versions of SDB
source$dx_1st <- toupper(source$dx_1st)

# write new dataset
write.csv(source, paste("//rfawin.partners.org/bwh-sleepepi-nsrr-staging/20231018-mignot-apoe/nsrr-prep/_releases/0.2.0/apoe-dataset-",ver,".csv",sep=""), row.names=F,
          na = "")

# create harmonized dataset:
source_h <- source[,c("apoe_id","visit",
                      "age", "gender", "bmi", 
                      "tst", "sleep_efficiency", "pct_s1",
                      "pct_s2", "pct_s3", "pct_rem", "tib")]
colnames(source_h) <- c("apoe_id","visit",
                        "nsrr_age", "nsrr_sex", "nsrr_bmi",
                        "nsrr_tst_f1", "nsrr_ttleffsp_f1",
                        "nsrr_pctdursp_s1",
                        "nsrr_pctdursp_s2",
                        "nsrr_pctdursp_s3",
                        "nsrr_pctdursp_sr", "nsrr_tib_f1")
source_h$nsrr_age_gt89 <- factor(source_h$nsrr_age>89, 
                                 levels=c(T, F),
                                 labels=c("yes","no"))

source_h$nsrr_sex <- recode(source_h$nsrr_sex, `M` = 'male', `F` = 'female', .default = '')

write.csv(source_h, paste("//rfawin.partners.org/bwh-sleepepi-nsrr-staging/20231018-mignot-apoe/nsrr-prep/_releases/0.2.0/apoe-harmonized-dataset-",ver,".csv",sep=""), row.names=F,
          na = "")
