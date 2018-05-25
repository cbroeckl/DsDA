// before starting this script, ensure that the R script has begun
// and instructed you to start script
// first change directory name to that project in which you are working
// see first line beneath opening bracket

public override void main()
{
  string proj=@"C:\Data\20171018-PMF-KWEBB-KW-20_neg2.PRO";
  // format directory as below
  // string proj=@"C:\Data\WRENS_20170524_final_dsda.PRO";
  string datadir=proj+@"\Data";
  double idlelimit=3000; // in seconds
  double maxtime=1020;   // in seconds
  
  
  int cycletime=100;
  int preload=500; 
  
  double idletime=0;  

  connect("epc");
  enable_data_capture();
  // reset_data();
  set_data_capture_range(105, 110, 50);
  send_cmd("setQuadConversionFactorV,16.625");
  stop_function("WrensStartScan","writePropertyQueueV");
  wait(10);
  start_function("WrensStartScan","writeQueueV");

  maxtime=maxtime-5;
  while(idletime < idlelimit) 
  {
    
    DateTime loopstarttime  = DateTime.Now;
    string dt = DateTime.Now.ToString("yyyy-MM-dd-HH-mm-ss");
    string outfile = proj+@"\settings\"+dt+@"_wrens.txt";

    string[] olddir = Directory.GetDirectories(datadir);
	string[] newdir = Directory.GetDirectories(datadir);
	//string dir=olddir[olddir.Length-1];
	int o=olddir.Length;
    int n=newdir.Length;
    print("waiting for new data file");
  	while (o == n) 
  	{
    	newdir = Directory.GetDirectories(datadir);
    	n=newdir.Length;
    	wait(1000);
        DateTime currenttime  = DateTime.Now;
        idletime = (currenttime - loopstarttime).TotalSeconds;
        print("waiting for new file: "+idletime.ToString());
        print("n direcories: o "+o.ToString()+" n "+n.ToString());
        if(idletime > idlelimit) 
   		{
      	  break;
    	}
  	}
    
    if(idletime > idlelimit) 
    {
      print("looping stopped, idlelimit was surpassed");
      break;
    }
    
	// string dir=newdir[newdir.Length-1];
    print("new .raw file written: starting loop");
  	//print(dir); 
    string commandfile=proj+@"\settings\active.txt";
    string[] commands=System.IO.File.ReadAllLines(commandfile);
    System.IO.File.WriteAllLines(outfile, commands);
    
	send_cmd("initPropertyQueueV");

    double currentrt = -1;
    bool proceed=false;
	while(!proceed) 
	{
		wait(100);
		string data = get_data();
        currentrt = get_retentionTime(data);
        // reset_data();
		if(currentrt>0 & currentrt <2)
		{
		  proceed=true;
		}
        DateTime currenttime  = DateTime.Now;
        idletime = (currenttime - loopstarttime).TotalSeconds;
        print("waiting for file start: "+idletime.ToString());
        if(idletime > idlelimit) 
   		{
          print("looping stopped, idlelimit was surpassed");
      	  break;
    	}
		
	}
    if(idletime > idlelimit) 
   	{
      print("looping stopped, idlelimit was surpassed");
      break;
    }
    print(currentrt.ToString());
    //start_function("WrensStartScan","writeQueueV");
    print("acquisition started, loading queue");
    int comlength=commands.Length-1;
    for(int x=2; x<comlength ; x++)  // from x=2 ; skip lockmass (0) and first MS (1)  
    {
      send_cmd(commands[x].ToString());
      if(x>preload) 
      {
        wait(cycletime/6); 
        //reset_data();
      }
    }
    DateTime loadendtime  = DateTime.Now;
    idletime = (loadendtime - loopstarttime).TotalSeconds;
    // wait(120000);
    proceed=false;
    while(!proceed) 
	{
		wait(1000);
		string data = get_data();
        currentrt = get_retentionTime(data);
        // reset_data();
        print("waiting for file end: retention time = "+currentrt.ToString());
		if(currentrt>maxtime | currentrt == 0)
		{
		  proceed=true;
		}		
	}
    //wait(10000);
    // reset_data();
  	// disable_data_capture();  
  	// stop_function("WrensStartScan","writeQueueV");
  }
  send_cmd("initPropertyQueueV");
  // reset_data();
  disable_data_capture();  
  stop_function("WrensStartScan","writeQueueV");
}
