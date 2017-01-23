import 'dart:io';

var filename = "allorders.txt";

//wget -q -U Mozilla -O output.mp3 "http://translate.google.com/translate_tts?ie=UTF-8&total=1&idx=0&textlen=32&client=tw-ob&q=Well Played&tl=En-us"

main() async {
    List<String> lines = await new File(filename).readAsLines();
    var orders = [];

    for (String line in lines) {
        var order;
        if (line.contains(new RegExp(r".*;"))) {
            order = line.split(r";");
        } else {
            order = [line, line];
        }
        order[0] = order[0].toLowerCase();
        order[0] = order[0].replaceAll(new RegExp(r"[-_.:\s]"), "");
        orders.add(order);
    }
    for (List order in orders) {
        Process.run("wget",
            ["-q",
             "-U", "Mozilla",
             "-O", order[0]+".mp3",
             "http://translate.google.com/translate_tts?ie=UTF-8&total=1&idx=0&textlen=32&client=tw-ob&q="+order[1]+"&tl=En-us"
            ]);
        sleep(new Duration(milliseconds: 100));
    }
}
