#include <iostream>

#include "controller.hh"
#include "timestamp.hh"
#include <climits>
#include <cstdint>
#include <vector>
#include <algorithm>

using namespace std;

// METHOD num:
// 1 padrao
// 2 AIMD
// 3 modelo melhorado
#define METHOD 3


// Globals
float rtt = 0;
float rtt_min = 80;
float rtt_max = 0;
float rtt_thresh = 50;
float backoff = 0;
float weight = 0.01;
float cwnd = 13.0;
float ssthresh = 60; // livro do tanembaum indica que valor 64 é bom para iniciar pq equivale ao tamanho de um pacote
float max_sstresh = 0;
float beta = 0.13; //0.5
float alpha = 0.75; //2
int timeout_counter = 0;
int timeout_thresh = 6;	
bool slow_start = true;
 

/* Default constructor */
Controller::Controller( const bool debug )
  : debug_( debug )
{
  debug_ = false;
}

/* Get current window size, in datagrams */
unsigned int Controller::window_size()
{
  /* Default: fixed window size of 100 outstanding datagrams */
  if (cwnd < 1) cwnd = 1.0;

  unsigned int the_window_size = (unsigned int) cwnd;

  //std::cout << " window size is " << the_window_size << std::endl;
  
if ( debug_ ) {
    cerr << "At time " << timestamp_ms()
	 << " window size is " << the_window_size << endl;
  }
  
  return the_window_size;	
}

/* A datagram was sent */
void Controller::datagram_was_sent( const uint64_t sequence_number,
				    /* of the sent datagram */
				    const uint64_t send_timestamp,
                                    /* in milliseconds */
				    const bool after_timeout
				    /* datagram was sent because of a timeout */ )
{
  /* Default: take no action */
  // caso cwnd ainda estiver grande
  if (after_timeout && cwnd > 2)
  {
    cwnd = cwnd/2;
  }

  if ( debug_ ) {
    cerr << "At time " << send_timestamp
	 << " sent datagram " << sequence_number << " (timeout = " << after_timeout << ")\n";
  }
}

/* An ack was received */
void Controller::ack_received( const uint64_t sequence_number_acked,
			       /* what sequence number was acknowledged */
			       const uint64_t send_timestamp_acked,
			       /* when the acknowledged datagram was sent (sender's clock) */
			       const uint64_t recv_timestamp_acked,
			       /* when the acknowledged datagram was received (receiver's clock)*/
			       const uint64_t timestamp_ack_received )
                               /* when the ack was received (by sender) */
{
  /* Default: take no action */
  
  if ( debug_ ) {
    cerr << "At time " << timestamp_ack_received
	 << " received ack for datagram " << sequence_number_acked
	 << " (send @ time " << send_timestamp_acked
	 << ", received @ time " << recv_timestamp_acked << " by receiver's clock)"
	 << endl;
  }

  rtt = (timestamp_ack_received - send_timestamp_acked);
  rtt_min = min(rtt, rtt_min); 
  //std::cout << "RTT min >>> " << rtt_min << endl;
  rtt_thresh = weight * rtt + (1 - weight) * rtt_thresh; 

  // AIMD + slow_start
  #if METHOD == 2 
    if (cwnd >= ssthresh)
    {
      slow_start = false;
      cwnd = cwnd * beta;	
      std::cout << "JANELA CONGEST_AVOID >>> " << cwnd << endl;
    } 
    else{
      slow_start = true;
      cwnd = cwnd + alpha;
    }
  #endif

  // AIMD + slow_start + timeout_counter
  // Add contador do timeout para esperar um pouco mais que 1000 ms, 
  // pois algumas vezes pode ter sido enviado pacotes em rajada
  #if METHOD == 3 
    alpha = 4.0;
    beta = 0.5;
    if (rtt > timeout_ms()) 
    {
      slow_start = false;
      if (timeout_counter >= timeout_thresh) //congest_avoid
      {
        timeout_counter = 0;
        cwnd *= (1.0 - (beta/cwnd));
      } 
      else{ 
        timeout_counter++;
      }
    } 
    else{ //slow_start
      slow_start = true;
      cwnd += (alpha/cwnd);
      timeout_counter++;	
    }
  #endif

 // AIMD + rtt_thresh 
  #if METHOD == 4 
    beta = 2.5;
    alpha = 5.125;
    if (rtt >  (1.4 * rtt_thresh)) 
    {
      cwnd = max(cwnd - ((double) beta/cwnd), 1.0); //min cwnd = 1
      std::cout << "CWND >>> " << cwnd << endl;
      rtt_thresh = rtt_min;
    }
    else 
    {
      cwnd += (float) alpha/cwnd;
    }
  #endif

}


/* How long to wait (in milliseconds) if there are no acks
   before sending one more datagram */
unsigned int Controller::timeout_ms()
{
  #if METHOD == 1 || METHOD == 2 // default e AIMD
    return 1000; /* timeout of one second */
  #endif

  #if METHOD == 3 || METHOD == 4 // modelo melhorado
    return 80;
  #endif


}
