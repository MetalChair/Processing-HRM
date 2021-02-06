import processing.serial.*;

Serial myPort;
DataManager mngr;
GraphDrawer graph;

color bg = #545863;
color dark = #073B4C;
color mid = #118AB2;
color high_mid = #06D6A0;
color bright = #FFD166;
color white = #F5F5F5;

void setup(){
  myPort = new Serial(this, Serial.list()[0], 115200);
  mngr = new DataManager(myPort);
  graph = new GraphDrawer(mngr);
  size(800, 600);
}

void draw(){
  background(bg);
  mngr.SerializeData();
  graph.Draw();
}

class GraphDrawer{
  
  DataManager _mngr;
  
  public GraphDrawer(DataManager mngr){
    this._mngr = mngr;
  }
  
  public void Draw(){
    //Draw HR related stuff
    int numHR = this._mngr.hr.length();
    for(int i = 0; i < numHR - 1; i++){
      int start[] = this._mngr.hr.get(i);
      int end[] = this._mngr.hr.get(i);
      //Convert from millis to seconds
      start[1] = start[1] / 100;
      end[1] = end[1] / 100;
      strokeWeight(10);
      stroke(bright);
      line(start[1], (height - start[0]), end[1], (height - end[0]));
    }
  }
}

public static Integer parseDataString(String val){
     try{
       int intVal = Integer.parseInt(trim(val));
       return intVal;
     }catch(Exception e){
         println("Error parsing val of", val);
         return null;
     }
}

class DataManager{
   TupleList hr;
   TupleList conf;
   TupleList oxy;
   Serial _port;
   //When did we start collecting data?
   int _startMillis = -1; 
   int status;
   
   public DataManager(Serial port){
     this.hr = new TupleList();
     this.conf = new TupleList();
     this.oxy = new TupleList();
     this.status = 0;
     this._port = port;
   }
   
   public void SerializeData(){
     while(_port.available() > 0){
       String data = _port.readStringUntil('\n');
       if(data != null){
          //Parse out the data
          data = data.substring(0, data.length() - 1); //Trim \n
          if(data.contains(":")){ 
            String val = data.substring(data.indexOf(":") + 1);
            //Parse out the status first so we can start collecting data
            if(data.contains("STAT")){
               Integer newStatus = parseDataString(val);
               if(newStatus != null && newStatus != this.status){
                  println("Status Changed To:", newStatus);
                  this.status = newStatus; 
               }
             }
             //Only capture data if a finger is detected
             if(this.status == 0){
               //Record the firt occurence
               if(this._startMillis == -1){
                 this._startMillis = millis();
               }
               if(data.contains("HEART"))
                 this.hr.add(val, millis() - this._startMillis, true);
               else if(data.contains("CONFI"))
                 this.conf.add(val, millis() - this._startMillis);
               else if(data.contains("OXY"))
                 this.oxy.add(val, millis() - this._startMillis);
             }
          }
       }
     }
   }
}

class TupleList{
   IntList _t1;
   IntList _t2;
   private int _length;
   public TupleList(){
      _t1 = new IntList();
      _t2 = new IntList();
      _length = 0;
   }
   
   public void add(int t1, int t2){
     this._t1.append(t1);
     this._t2.append(t2);
     _length++;
   }
   
   public void add(String t1, int t2){
     Integer val = parseDataString(t1);
     if(val == null)
       return;
     this.add(val, t2);
   }
   public void add(String t1, int t2, boolean zeroCheck){
     Integer val = parseDataString(t1);
     if(val == null || (val == 0 && zeroCheck))
       return;
     this.add(val, t2);
   }
   
   public int length(){
      return _length;
   }
   public int[] get(int idx){
     int tuple[] = {this._t1.get(idx), this._t2.get(idx)};
     return tuple;
   }
}
