#!/bin/bash
set -x 

USERNAME=goluck
nRUN=35
TAM_CWND=35
EXPERIMENT_PATH=~/Documents/TP2/tp2-congestionControl/datagrump/


RunMake(){

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
	   ./run-contest $USERNAME >> results-cwnd${TAM_CWND}.dat 2>&1
		wait
        echo "================================" >> results-cwnd${TAM_CWND}.dat 2>&1
	done	


    echo "------------- Computing Average -----------"
    echo " "

    # procura no arquivo .dat o delay do sinal e soma
    averageDelay=`cat results-cwnd${TAM_CWND}.dat | gawk '$3 ~ /signal/  {soma+=$5; media=soma/35} END {printf "%.2f",media}'` 
    # procura no arquivo .dat o throughput do sinal e soma
    averageThroughput=`cat results-cwnd${TAM_CWND}.dat | gawk '$2 ~ /throughput/  {soma+=$3; media=soma/35} END {printf "%.2f",media}'`
 
    cd ${EXPERIMENT_PATH}

    if [ "results-exer1.tr" == " " ]; then
        echo "#cwnd #averageDelay #averageThroughput" > results-exer1.tr 2>&1
        chmod 6777 results-exer1.tr
        echo $TAM_CWND $averageDelay $averageThroughput >> results-exer1.tr 2>&1
    fi
    echo $TAM_CWND $averageDelay $averageThroughput >> results-exer1.tr 2>&1
    

	echo "-----------Terminou-----------"	
}


RunExercise2(){
	echo "-----------Iniciando experimentos-----------"

}


# limpa arquivos
Clean(){

     cd ${EXPERIMENT_PATH}

    if [ "$1" == "" ]; then
        Clean "tmp"
        Clean "dat"
        Clean "plt"
        Clean "tr"
        Clean "xr"
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
    echo "Usage: ./run.sh <COMMAND>"
    echo "Commands:"
    echo "   -run1|--exe1                     Run the exercise 1: throughtput vs delay"
    echo "   -run2|--exe2                     Run the exercise 2: M"
    echo "   -make|--make                     Run configure and make"
    echo "      -c|--clean                    Clean out the .data files"
    echo "           OPTIONS: file extension   Clean out .<file extension> files"
    echo "      -h|--help                     Show this help message"
    echo "Examples:"
    echo "    ./run.sh -a"
    echo "    ./run.sh -b"
    echo "    ./run.sh -c .dat"
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


