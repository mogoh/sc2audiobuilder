import 'dart:html';
import 'dart:async';

List<SC2Event> sC2EventList = new List<SC2Event>();
int time = 0;
Timer timer;
bool initialized = false;
SpanElement clock;
ButtonElement playPauseButton;
TextAreaElement outputTextArea;
TextAreaElement inputTextArea;
bool inputClicked = false;

void main() {
    playPauseButton = querySelector("#playButton");
    playPauseButton.onClick.listen(start);
    clock = querySelector("#clock");
    outputTextArea = querySelector("#output");
    querySelector("#resetButton").onClick.listen(reset);
    inputTextArea = querySelector("#input");
    inputTextArea.onClick.listen(inputFirstClick);
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

void inputFirstClick(Event e) {
    if (!inputClicked) {
        inputTextArea.select();
        inputClicked = true;
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
            String order = line;
            //  get rid of supply number
            order = order.replaceFirst(new RegExp(r"^\s*\d+\s*\-?"), "");
            //  Match order
            Match matchOrder = new RegExp(r"([a-zA-Z.:\d]+\s*)+[a-zA-Z.:\d]*"
                    ).firstMatch(order);
            order = matchOrder.group(0);
            order = order.trim();

            //  extract Time
            Match matchTime = new RegExp(r"\d?\d\:\d\d").firstMatch(line);
            int time = parseTime(matchTime.group(0));

            if (line.toLowerCase().endsWith("(chronoboosted)")) {
                sC2EventList.add(new SC2Event(time, "chronoboost"));
            }

            sC2EventList.add(new SC2Event(time, order));
        }

        //  Returning reminder.
        if (line.toLowerCase().startsWith("reminder:")) {
            String reminder;
            String startString;
            int start;
            String everyString;
            int every;

            reminder = line.replaceFirst(new RegExp(r"^reminder:",
                    caseSensitive: false), "");
            reminder = reminder.replaceFirst(new RegExp(r"start:.*$",
                    caseSensitive: false), "");
            reminder = reminder.trim();

            startString = line.replaceFirst(new RegExp(r"^.*start:",
                    caseSensitive: false), "");
            startString = startString.replaceFirst(new RegExp(r"every:.*$",
                    caseSensitive: false), "");
            startString = startString.trim();
            start = parseTime(startString);

            everyString = line.replaceFirst(new RegExp(r"^.*every:",
                    caseSensitive: false), "");
            everyString = everyString.trim();
            every = parseTime(everyString);
            if (start <= 0) {
                start = 0;
            }
            if (every <= 0) {
                every += 1;
            }

            while (start < 10000) {
                sC2EventList.add(new SC2Event(start, reminder));
                start += every;
            }
        }
        sC2EventList.sort((e1, e2) => e1.time - e2.time);

        //  Merge multiple events
        for (int i = 0; i < sC2EventList.length; i += 1) {
            int j = i + 1;
            if (sC2EventList.length == j) {
                break;
            }
            while (sC2EventList[i].time >= sC2EventList[j].time - 2) {
                String e1 = sC2EventList[i].order.replaceAll(new RegExp(r"\s*"),
                        "").toLowerCase();
                String e2 = sC2EventList[j].order.replaceAll(new RegExp(r"\s*"),
                        "").toLowerCase();
                if (e1 == e2) {
                    sC2EventList[i].times += 1;
                    sC2EventList.removeAt(j);
                } else {
                    j += 1;
                }
                if (sC2EventList.length >= j) {
                    break;
                }
            }
        }
    }
}

int parseTime(String time) {
    List<String> stringTime = time.split(":");
    int minutes = int.parse(stringTime[0]);
    int seconds = int.parse(stringTime[1]);
    return minutes * 60 + seconds;
}

void run() {
    timer = new Timer.periodic(const Duration(milliseconds: 720), pulse);
}

void pulse(Timer timer) {
    setTime();
    //  Check for empty list
    if (sC2EventList.isEmpty) {
        timer.cancel();
    } //  Play Event, 2 seconds look ahead
    else if (sC2EventList.first.time <= time + 2) {
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
    String order = sC2Event.order;

    order = order.toLowerCase();
    order = order.replaceAll(new RegExp(r"[-_.:\s]"), "");
    new AudioElement("./sounds/" + order + ".mp3").play();

    if (sC2Event.times > 1 && sC2Event.times <= 24) {
        new Timer(const Duration(milliseconds: 1500), () {
            new AudioElement("./sounds/" + sC2Event.times.toString() +
                    "times.mp3").play();
        });
    } else if (sC2Event.times > 1 && sC2Event.times > 24) {
        new Timer(const Duration(milliseconds: 1500), () {
            new AudioElement("./sounds/manytimes.mp3").play();
        });
    }
}

void println(String text) {
    outputTextArea.text += text + "\n";
    //  Scroll down
    outputTextArea.scrollTop = outputTextArea.scrollHeight;
}

void printEvent(SC2Event sC2Event) {
    String seconds = (sC2Event.time % 60).toString();
    if (seconds.length == 1) {
        seconds = "0" + seconds;
    }
    String minutes = (sC2Event.time ~/ 60).toString();
    if (minutes.length == 1) {
        minutes = "0" + minutes;
    }
    String time = minutes + ":" + seconds;

    //  times an event occur
    String times = "";
    if (sC2Event.times > 1) {
        times = " " + sC2Event.times.toString() + "x";
    }

    outputTextArea.text += "[" + time + "] " + sC2Event.order + times + "\n";
    //  Scroll down
    outputTextArea.scrollTop = outputTextArea.scrollHeight;
}

void setTime() {
    String seconds = (time % 60).toString();
    if (seconds.length == 1) {
        seconds = "0" + seconds;
    }
    String minutes = (time ~/ 60).toString();
    if (minutes.length == 1) {
        minutes = "0" + minutes;
    }
    clock.text = minutes + ":" + seconds;
}

class SC2Event {
    int time;
    String order;
    int times;

    SC2Event(this.time, this.order, {this.times: 1});
}
