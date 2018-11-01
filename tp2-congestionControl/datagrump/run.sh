#!/bin/bash
set -x 

USERNAME=JasonCrocs
nRUN=35
TAM_CWND=13
EXPERIMENT_PATH=~/Documents/TP2/tp2-congestionControl/datagrump/
col="3"


RunMake(){

    #teclado
    setxkbmap -model abnt2 -layout br

    #ipv4
    sudo sysctl -w net.ipv4.ip_forward=1
    
    # configure e make
    cd ..
    ./autogen.sh
    ./configure && make
    cd ${EXPERIMENT_PATH}
}


RunExercise1(){

    echo "-----------Starting Experiment-----------"
    
    echo "Resultados com window_size = ${TAM_CWND} \n" > results-cwnd${TAM_CWND}.dat 2>&1
    chmod 6777 results-cwnd${TAM_CWND}.dat

    for i in $(seq $nRUN)
    do
        echo "loop $i"
       ./run-contest $USERNAME >> results-cwnd${TAM_CWND}.dat 2>&1
        wait
       echo "================================" >> results-cwnd${TAM_CWND}.dat 2>&1
    done    


    echo "------------- Computing Average -----------"
    echo " "


    cd ${EXPERIMENT_PATH}
    arq=results-cwnd${TAM_CWND}.dat

    # Delay >> MEAN, SD e ERRO 
    averageDelay=`cat ${arq} | awk -v nr=$nRUN '$3 ~ /signal/  {soma+=$5; media=soma/nr} END {printf "%.2f",media}'` 
    stdDelay=`gawk -v med=$averageDelay -v nr=$nRUN '$3 ~ /signal/ {aux=$5-med; stDev+=aux*aux;}END{ printf "%.2f", sqrt(stDev/(nr-1));}' ${arq}`
    erroDelay=$(CalculaErro ${stdDelay} ${arq})
    LI_Delay=`echo "($averageDelay - $erroDelay)" | bc | gawk '{printf "%.2f", $0}'`
    LS_Delay=`echo "($averageDelay + $erroDelay)" | bc | gawk '{printf "%.2f", $0}'`

    # Throughput >> MEAN, SD e ERRO 
    averageThroughput=`cat ${arq} | gawk '$2 ~ /throughput/  {soma+=$3; media=soma/35} END {printf "%.2f",media}'`
    stdThroughput=`gawk -v med=$averageThroughput -v nr=$nRUN '$2 ~ /throughput/ {aux=$3-med; stDev+=aux*aux;}END{ printf "%.2f", sqrt(stDev/(nr-1));}' ${arq}`
    erroThroughput=$(CalculaErro ${stdThroughput} ${arq})
    LI_Throughput=`echo "($averageThroughput - $erroThroughput)" | bc | gawk '{printf "%.2f", $0}'`
    LS_Throughput=`echo "($averageThroughput + $erroThroughput)" | bc | gawk '{printf "%.2f", $0}'`

    potencia=`echo "scale=3; (($averageThroughput / $averageDelay)*1000)" | bc`

    arqFinal=results-exer1.tr

    if [ -e "${arqFinal}" ]; then # se arquivo já existe ..
        echo $TAM_CWND $averageDelay $LI_Delay $LS_Delay $averageThroughput $LI_Throughput $LS_Throughput $potencia >> ${arqFinal} 2>&1
    else
        echo "#cwnd #averageDelay #LI_Delay #LS_Delay #averageThroughput #LI_Throughput #LS_Throughput #potencia" > ${arqFinal} 2>&1
        chmod 6777 ${arqFinal}
        echo $TAM_CWND $averageDelay $LI_Delay $LS_Delay $averageThroughput $LI_Throughput $LS_Throughput $potencia >> ${arqFinal} 2>&1
        
    fi    

    echo "-----------Terminou-----------"   
}


RunExercise2(){
    echo "-----------Iniciando experimentos - exercicio  AIMD -----------"
    
    echo "Resultados com window_size = ${TAM_CWND} e AIMD implementado \n" > results-cwnd${TAM_CWND}.dat 2>&1
    chmod 6777 results-cwnd${TAM_CWND}.dat

    for i in $(seq $nRUN)
    do
        echo "loop $i"
       ./run-contest $USERNAME >> results-cwnd${TAM_CWND}.dat 2>&1
        wait
       echo "================================" >> results-cwnd${TAM_CWND}.dat 2>&1
    done    
    echo "-----------Terminou-----------"   

}


RunExercise3(){
    echo "-----------Iniciando experimentos - exercicio C -----------"
    
    echo "Resultados com window_size = ${TAM_CWND} \n" > results-cwnd${TAM_CWND}.dat 2>&1
    chmod 6777 results-cwnd${TAM_CWND}.dat

    for i in $(seq $nRUN)
    do
        echo "loop $i"
       ./run-contest $USERNAME >> results-cwnd${TAM_CWND}.dat 2>&1
        wait
        echo "nRUN $i" >> results-cwnd${TAM_CWND}.dat 2>&1
        echo "================================" >> results-cwnd${TAM_CWND}.dat 2>&1
    done    

    cd ${EXPERIMENT_PATH}
    arq=results-cwnd${TAM_CWND}.dat
    arqFinal=results-exer3.tr

    potencia=`cat ${arq} | gawk '$1 ~ /Power/ {print $2}' >> ${arqFinal}`

    if [ -e "${arqFinal}" ]; then # se arquivo já existe ..
        echo $potencia >> ${arqFinal} 2>&1
    else
        echo "#potencia" > ${arqFinal} 2>&1
        chmod 6777 ${arqFinal}
        echo $potencia >> ${arqFinal} 2>&1
        
    fi  

    echo "-----------Terminou-----------"   

}

CalculaErro(){
  Z=1.96
  std=$1
  errop=`gawk -v stdev=$std -v z=$Z -v nr=$nRUN 'END{printf("%.2f",(z*stdev)/sqrt(nr))}' ${2}`
  echo "$errop"
}


# limpa arquivos
Clean(){

     cd ${EXPERIMENT_PATH}

    if [ "$1" == "" ]; then
        Clean "dat"
        Clean "tr"
    else
        count=`find ./ -maxdepth 1 -name "*.${1}" | wc -l`
        if [ ${count} != 0 ]; then
            rm *.${1}
            echo "Removed ${count} .${1} files"
        fi
    fi

}


# Print usage instructions
ShowUsage()
{
    echo -e "${GRAY}\n"
    echo "Script to run Control Congestion"
    echo "Usage: sh run.sh <COMMAND>"
    echo "Commands:"
    echo "   -run1|--exe1                      Run the exercise 1: throughtput vs delay"
    echo "   -run2|--exe2                      Run the exercise 2: AIMD"
    echo "   -run3|--exe3                      Run the exercise 3: AIMD + timeout"
    echo "   -make|--make                      Run configure and make"
    echo "      -c|--clean                     Clean out the .data files"
    echo "           OPTIONS: file extension   Clean out .<file extension> files"
    echo "      -h|--help                      Show this help message"
    echo "Examples:"
    echo "    sh run.sh -a"
    echo "    sh run.sh -b"
    echo "    sh run.sh -c .dat"
    echo -e "${WHITE}\n"
}


main()
{
    # $1 parametro 1 , $2 parametro 2 ...

    case "$1" in
        '-run1'|'--exe1' )
            RunExercise1
        ;;

        '-run2'|'--exe2' )
            RunExercise2 
        ;;
        '-run3'|'--exe3' )
            RunExercise3 
        ;;

        '-make'|'--make' )
            RunMake 
        ;;

        '-c'|'--clean' )
            Clean $2
        ;;

        *)
            ShowUsage
            exit 1
        ;;
    esac

    exit 0

}

main "$@"



