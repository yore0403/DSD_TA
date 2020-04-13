#!/bin/sh

#set parameter
STUDENT_SCORE_FILE=student_score.txt #output result to this file
main_dir_prefix="DSD_HW1_"
Q_dir=("1-CR_Adder" "2-barrel_shifter" "3-ASU")
hw_dir="HW1_students" #student's homework 
tb_dir="HW1_tb" #testbench
count=1

#ERROR_MESSAGE "error_type" $error_var output_file
ERROR_MESSAGE(){
[ -e $3 ] && output=$3 || output=/dev/null
case $1 in
  "NOT_FOUND") 
    echo "ERROR: \"$2\" not found. " >> $output
    ;;
  "WRONG_FORMAT")
    echo "ERROR: \"$2\" has wrong format. " >> $output
    ;;
  "NO_DELAY")
    echo "WARNING: \"$2\" no delay. " >> $output
    ;;
  "REDUNDANT")
    echo "WARNING: redundant file \"$2\". " >> $output
    ;;
  #"SOMETHING_ERROR")
  # ...
  # ;;
esac
}

#clean output file
clean(){
file=$1
[ -f $file ]&& rm $file; touch $file
}

#beginning of output file
set_bof(){
file=$1
echo "===========================================">> $file
echo "DSD HW1 scoring system">> $file
echo "Create by b05901084">> $file
echo "Execute time: $(date +'%Y-%m-%d %H:%M:%S')" >> $file
echo "===========================================">> $file
}

#check if delay exist
#has_delay #delay *.v outputfile
check_delay(){
delay_cnt=$(grep -c "$1" $2)
p=$2
[ $delay_cnt == 0 ] && ERROR_MESSAGE "NO_DELAY" "${p##*/}" $STUDENT_SCORE_FILE

}



#check all file are exist
check_file_exist() {
has_error=0
while [ $# != 0 ]
do 
if [ ! -f $1 ]
then
p=$1
ERROR_MESSAGE "NOT_FOUND" "${p##*/}" $STUDENT_SCORE_FILE
has_error=1
fi
shift
done
return $has_error

}

check_redundant_file() {
i=0
dir=$1
shift
while [ $# != 0 ]
do 
  file[i]=$1
  i=`expr $i + 1`
  shift
done  
echo ${file[*]}
has_redundant=0
[ $mode == 1 ] && lsdir=$dir*.v
for i in $(ls $lsdir);
do  
   for f in ${file[*]};
   do
     [ $f == $i ] && continue 2
   done
   ERROR_MESSAGE "REDUNDANT" "${i##*/}" $STUDENT_SCORE_FILE 
   
done
unset file


return $has_error

}


score(){
  
  student_dir=$1

  #check if main dir prefix is correct
  [[ ${student_dir:0:${#main_dir_prefix}} != $main_dir_prefix ]] && ERROR_MESSAGE "WRONG_FORMAT" $student_dir ../$STUDENT_SCORE_FILE
  
  student_ID=${student_dir:${#main_dir_prefix}}
  echo "========================== "$student_ID" =========================="
  
  echo "================ "$student_ID" ================" >> $STUDENT_SCORE_FILE
  
  current_dir=../../$hw_dir/$student_dir/
  #check_redundant_file $current_dir ${Q_dir[*]} report*
  #1-CR_Adder
  cd ${Q_dir[0]}
  STUDENT_SCORE_FILE="../"$STUDENT_SCORE_FILE
  echo "1-CR_Adder" >> $STUDENT_SCORE_FILE
  current_dir=../../$hw_dir/$student_dir/${Q_dir[0]}
  check_redundant_file  $current_dir/ adder.v adder_gate.v
  if [[ -d ${current_dir} ]];then
    
    check_file_exist $current_dir/adder.v && ncverilog adder_test.v $current_dir/adder.v +access+r
    check_file_exist $current_dir/adder_gate.v && ncverilog adder_test.v $current_dir/adder_gate.v +access+r
    echo "" >> $STUDENT_SCORE_FILE
    check_delay "#1" $current_dir/adder_gate.v
  else
    ERROR_MESSAGE "NOT_FOUND" ${Q_dir[0]} $STUDENT_SCORE_FILE
  fi
  cd ..
  
  #2-barrel_shifter
  cd ${Q_dir[1]}
  
  echo -e "2-barrel_shifter" >> $STUDENT_SCORE_FILE 
  current_dir=../../$hw_dir/$student_dir/${Q_dir[1]}
  
  if [[ -d ${current_dir} ]];then
    
    check_file_exist $current_dir/barrel_shifter.v && ncverilog barrel_test.v $current_dir/barrel_shifter.v +access+r
    check_file_exist $current_dir/barrel_shifter_gate.v && ncverilog barrel_gate_test.v $current_dir/barrel_shifter_gate.v +access+r
    echo "" >> $STUDENT_SCORE_FILE
    
    check_delay "#1" $current_dir/barrel_shifter_gate.v
  else
    ERROR_MESSAGE "NOT_FOUND" ${Q_dir[1]} $STUDENT_SCORE_FILE
  fi
  cd ..
  
  #3-ASU
  cd ${Q_dir[2]}
  echo -e "3-ASU" >> $STUDENT_SCORE_FILE 
  current_dir=../../$hw_dir/$student_dir/${Q_dir[2]}
  adder_dir=../../$hw_dir/$student_dir/${Q_dir[0]}
  shift_dir=../../$hw_dir/$student_dir/${Q_dir[1]}  
  
  if [[ -d ${current_dir} ]];then
    
    check_file_exist $current_dir/asu.v && ncverilog asu_test.v $current_dir/asu.v $adder_dir/adder.v $shift_dir/barrel_shifter.v +access+r
    check_file_exist $current_dir/asu_gate.v && ncverilog asu_gate_test.v $current_dir/asu_gate.v $adder_dir/adder_gate.v $shift_dir/barrel_shifter_gate.v +access+r
    echo "" >> $STUDENT_SCORE_FILE
    check_delay "#2.5" asu_gate.v
    
    echo -e "3-ASU opt" >> $STUDENT_SCORE_FILE 
    check_file_exist $current_dir/asu_gate.v $current_dir/adder_gate_opt.v $current_dir/barrel_shifter_gate_opt.v && ncverilog asu_gate_test.v $current_dir/asu_gate.v $current_dir/adder_gate_opt.v $current_dir/barrel_shifter_gate_opt.v +access+r
    echo "" >> $STUDENT_SCORE_FILE
    check_delay "#1" $current_dir/adder_gate_opt.v
    check_delay "#1" $current_dir/barrel_shifter_gate_opt.v
  else
    ERROR_MESSAGE "NOT_FOUND" ${Q_dir[2]} $STUDENT_SCORE_FILE
  fi
  cd ..  
  STUDENT_SCORE_FILE=${STUDENT_SCORE_FILE#*/}

  echo -e "\n" >> $STUDENT_SCORE_FILE
}



main(){

clean $STUDENT_SCORE_FILE
set_bof $STUDENT_SCORE_FILE


cd $tb_dir/
STUDENT_SCORE_FILE="../"$STUDENT_SCORE_FILE

cnt=0
if [ -e $1 ];then
# $sh HW1_script.sh
#run all student's homework in $hw_dir
 for student_dir in $(ls ../$hw_dir/);
 do  
   score $student_dir
   cnt=`expr $cnt + 1`
   echo $cnt
   [ $cnt == 1 ] && break 2 
 done
else
# $sh HW1_script.sh [student_ID]
#run specific student's homework in $hw_dir
  score $main_dir_prefix$1
fi

cd ..

}
main "$@"