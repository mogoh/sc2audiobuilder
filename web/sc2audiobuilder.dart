import 'dart:html';
import 'dart:async';

List<SC2Event> sC2EventList = new List<SC2Event>();
int time = 0;
Timer timer;
bool initialized = false;
SpanElement clock;

void main() {
    querySelector("#startButton").onClick.listen(start);
    querySelector("#pauseButton").onClick.listen(pause);
    querySelector("#resetButton").onClick.listen(reset);
    clock = querySelector("#clock");
}

void reset(Event e) {
    if (timer != null) {
        timer.cancel();
    }
    time = 0;
    setTime();
    sC2EventList = new List<SC2Event>();
    initialized = false;
    querySelector("#output").text = "";
}

void pause(Event e) {
    if (initialized) {
        if (timer.isActive) {
            timer.cancel();
        } else {
            timer = new Timer.periodic(const Duration(milliseconds: 768), pulse
                    );
        }
    }
}

void start(Event e) {
    parse();
    initialized = true;
    run();
}

void parse() {
    TextAreaElement inputTA = querySelector("#input");
    String input = inputTA.value;

    List<String> lines = input.split("\n");

    for (String line in lines) {
        //Tests if line is a build order line
        RegExp buildOrderLine = new RegExp(
                r"^\s*\d+.*([a-zA-Z.:]+\s*)+[a-zA-Z.:].*\d\d\:\d\d.*");
        if (line.contains(buildOrderLine)) {
            String unit = line;
            //get rid of supply number
            unit = unit.replaceFirst(new RegExp(r"^\s*\d+"), "");
            Match matchOrder = new RegExp(r"([a-zA-Z.:\d]+\s*)+[a-zA-Z.:\d]\s"
                    ).firstMatch(unit);
            unit = matchOrder.group(0).toLowerCase();
            unit = unit.replaceAll(new RegExp(r"[.:\s]"), "");

            Match matchTime = new RegExp(r"\d?\d\:\d\d").firstMatch(line);
            List<String> stringTime = matchTime.group(0).split(":");
            int minutes = int.parse(stringTime[0]);
            int seconds = int.parse(stringTime[1]);
            int time = minutes * 60 + seconds;

            sC2EventList.add(new SC2Event(time, "build", unit, 1));
        }
    }
}

void run() {
    println("gl hf");
    new AudioElement("./sounds/glhf.ogg").play();
    timer = new Timer.periodic(const Duration(milliseconds: 768), pulse);
}

void pulse(Timer timer) {
    setTime();
    if (sC2EventList.first.time <= time) {
        SC2Event event = sC2EventList.first;
        sC2EventList.removeAt(0);

        println(event.time.toString() + " " + event.unit);
        play(event);

        if (sC2EventList.isEmpty) {
            timer.cancel();

            new Timer(const Duration(seconds: 2), () {
                println("gg");
                new AudioElement("./sounds/gg.ogg").play();
            });
        }
    }
    time += 1;
}

void play(SC2Event sC2Event) {
    String unit = sC2Event.unit;
    new AudioElement("./sounds/" + unit + ".ogg").play();

}

void println(String text) {
    querySelector("#output").text += text + "\n";
}

void setTime() {
    String seconds = (time % 60).toString();
    if (seconds.length == 1) {
        seconds = "0"+seconds;
    }
    String minutes = (time ~/ 60).toString();
    if (minutes.length == 1) {
        minutes = "0"+minutes;
    }
    clock.text = minutes+":"+seconds;
}

class SC2Event {
    int time;
    //maybe unnessecary
    String order;
    String unit;
    int number;

    SC2Event(this.time, this.order, this.unit, this.number);
}
