#!/bin/bash 

export PYTHONPATH=$PYTHONPATH:$XLIT_HOME/src

. $1

fcorpus_fname="$data_dir/train.$src_lang"
ecorpus_fname="$data_dir/train.$tgt_lang"
test_fcorpus_fname="$data_dir/test.$src_lang"
test_ecorpus_fname="$data_dir/test.$tgt_lang"

if [ -d $workspace_dir ]
then     
    rm -rf $workspace_dir
fi 

mkdir -p $workspace_dir/{evaluation,model,log}

cp $1 $workspace_dir/train.conf

# unsupervised 
# train
time python $XLIT_HOME/src/cfilt/transliteration/transliterate_cli.py unsup_train \
    $fcorpus_fname $ecorpus_fname $config_fname $lm_fname $workspace_dir/model/translit.model > $workspace_dir/log/train.log 2>&1 

### supervised 
### train
##time python $XLIT_HOME/src/cfilt/transliteration/transliterate_cli.py sup_train \
##    $fcorpus_fname $ecorpus_fname $config_fname $workspace_dir/model/translit.model > $workspace_dir/log/train.log 2>&1 
#
#
# test
time python $XLIT_HOME/src/cfilt/transliteration/transliterate_cli.py transliterate_topn \
    $workspace_dir/model/translit.model $lm_fname $test_fcorpus_fname $workspace_dir/evaluation/test.50best.$tgt_lang 50 $decoder_params_fname > $workspace_dir/log/decode.log 2>&1 

# convert to k-best format 
python $XLIT_HOME/src/cfilt/transliteration/news2015_utilities.py  convert_to_kbest_format  \
    $workspace_dir/evaluation/test.50best.$tgt_lang $workspace_dir/evaluation/test.nbest.$tgt_lang 10 

## rule based 
#python /home/development/anoop/installs/indic_nlp_library/src/indicnlp/transliterate/unicode_transliterate.py \
#        $test_fcorpus_fname \
#        $workspace_dir/evaluation/test.$tgt_lang \
#        $src_lang $tgt_lang 

## convert to nbest format 
#python $XLIT_HOME/src/cfilt/transliteration/news2015_utilities.py  convert_to_nbest_format  \
#    $workspace_dir/evaluation/test.$tgt_lang $workspace_dir/evaluation/test.nbest.$tgt_lang

# generate NEWS 2015 evaluation format output file 
python $XLIT_HOME/src/cfilt/transliteration/news2015_utilities.py gen_news_output \
        "$data_dir/test.id" \
        "$ref_xml" \
        "$workspace_dir/evaluation/test.nbest.$tgt_lang" \
        "$workspace_dir/evaluation/test.nbest.$tgt_lang.xml" \
        "$systemtype" "$dataset" "$src_lang" "$tgt_lang"  

# run evaluation 
python $XLIT_HOME/scripts/news_evaluation_script/news_evaluation.py \
        -t $ref_xml \
        -i $workspace_dir/evaluation/test.nbest.$tgt_lang.xml \
        -o $workspace_dir/evaluation/test.nbest.$tgt_lang.detaileval.csv \
        > $workspace_dir/evaluation/test.nbest.$tgt_lang.eval 

