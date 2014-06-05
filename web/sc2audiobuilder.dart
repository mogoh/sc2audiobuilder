import 'dart:html';
import 'dart:async';

List<SC2Event> sC2EventList = new List<SC2Event>();
int time = 0;
Timer timer;
bool initialized = false;
SpanElement clock;
ButtonElement playPauseButton;
TextAreaElement outputTextArea;

void main() {
    playPauseButton = querySelector("#playButton");
    playPauseButton.onClick.listen(start);
    clock = querySelector("#clock");
    outputTextArea = querySelector("#output");
    querySelector("#resetButton").onClick.listen(reset);
}

void reset(Event e) {
    if (timer != null) {
        timer.cancel();
    }
    time = 0;
    setTime();
    sC2EventList = new List<SC2Event>();
    initialized = false;
    playPauseButton.text = "Play";
    querySelector("#output").text = "";
}


void start(Event e) {
    if (!initialized) {
        playPauseButton.text = "Pause";
        parse();
        initialized = true;
        run();
    } else {
        if (timer.isActive) {
            playPauseButton.text = "Play";
            timer.cancel();
        } else {
            playPauseButton.text = "Pause";
            timer = new Timer.periodic(const Duration(milliseconds: 768), pulse
                    );
        }
    }
}

void parse() {
    TextAreaElement inputTA = querySelector("#input");
    String input = inputTA.value;

    List<String> lines = input.split("\n");

    for (String line in lines) {
        //  Tests if line is a build order line
        //  This RegExp is buggy but won't be fixed until dart is fixed.
        //  https://code.google.com/p/dart/issues/detail?id=19193
        //  https://stackoverflow.com/questions/24027524/why-does-dart-not-match-this-regex
        RegExp buildOrderLine = new RegExp(
                r"^\s*\d+\s*\-?\s*([a-zA-Z.:\d]+\s*)+.*\d\d:\d\d.*");
        if (line.contains(buildOrderLine)) {
            String unit = line;
            //  get rid of supply number
            unit = unit.replaceFirst(new RegExp(r"^\s*\d+"), "");
            //  Match order
            Match matchOrder = new RegExp(r"([a-zA-Z.:\d]+\s*)+[a-zA-Z.:\d]\s"
                    ).firstMatch(unit);
            unit = matchOrder.group(0).toLowerCase();
            unit = unit.replaceAll(new RegExp(r"[-_.:\s]"), "");

            //  extract Time
            Match matchTime = new RegExp(r"\d?\d\:\d\d").firstMatch(line);
            List<String> stringTime = matchTime.group(0).split(":");
            int minutes = int.parse(stringTime[0]);
            int seconds = int.parse(stringTime[1]);
            int time = minutes * 60 + seconds;

            if (line.toLowerCase().endsWith("(chronoboosted)")) {
                sC2EventList.add(new SC2Event(time, "chronoboost"));
            }

            sC2EventList.add(new SC2Event(time, unit));
        }
    }
}

void run() {
    timer = new Timer.periodic(const Duration(milliseconds: 720), pulse);
}

void pulse(Timer timer) {
    setTime();
    //  Check for empty list
    if (sC2EventList.isEmpty) {
        timer.cancel();
    }
    //  Play Event, 2 seconds look ahead
    else if (sC2EventList.first.time <= time+2) {
        SC2Event event = sC2EventList.first;
        sC2EventList.removeAt(0);

        printEvent(event);
        play(event);

        //  Check for empty list
        if (sC2EventList.isEmpty) {
            timer.cancel();
        }
    }
    time += 1;
}

void play(SC2Event sC2Event) {
    String unit = sC2Event.unit;
    new AudioElement("./sounds/" + unit + ".ogg").play();
}

void println(String text) {
    outputTextArea.text += text + "\n";
    //  Scroll down
    outputTextArea.scrollTop = outputTextArea.scrollHeight;
}

void printEvent(SC2Event sC2Event) {
    String seconds = (sC2Event.time % 60).toString();
    if (seconds.length == 1) {
        seconds = "0"+seconds;
    }
    String minutes = (sC2Event.time ~/ 60).toString();
    if (minutes.length == 1) {
        minutes = "0"+minutes;
    }
    String time = minutes+":"+seconds;

    outputTextArea.text += "["+time+"] "+ sC2Event.unit + "\n";
    //  Scroll down
    outputTextArea.scrollTop = outputTextArea.scrollHeight;
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
    String unit;

    SC2Event(this.time, this.unit);
}
