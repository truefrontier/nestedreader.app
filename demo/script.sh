# The take, one gesture per line. Sourced by `record.sh run` after recording starts; helpers and
# coordinates are window-relative (see record.sh). Marks land in marks.log for checking the beats.

ANSWER_WAIT=34   # seconds for a Quick Answer to stream in on the Claude plan
PAGE_WAIT=42     # seconds for a New Page to stream in
park_in_gutter() { move 380 620; }   # off the text and off any card, so a peeked answer closes

mark "tree: open the root page"
move 110 330; sleep 0.6
click 110 144; sleep 2.5

mark "select: This replay is thought to move fragile memories into the cortex"
move 700 500; sleep 0.5
select_text 836 351 910 379; sleep 1.6

mark "ask: type the question"
type_text "How do we know the copy survives without the hippocampus?"; sleep 0.9
mark "ask: quick answer"
key return
sleep $ANSWER_WAIT

mark "close: the dotted highlight stays"
move 700 379; sleep 0.4
key escape; sleep 1.4
park_in_gutter; sleep 0.8
mark "hover: the answer comes back"
move 640 379; sleep 0.3; move 700 379; sleep 2.8
park_in_gutter; sleep 1.6

mark "select: what decides which experiences get replayed"
select_text 862 540 770 568; sleep 1.6
mark "ask: type the second question"
type_text "Which experiences get replayed?"; sleep 0.9
mark "new page beside"
key return command
sleep $PAGE_WAIT

mark "tree: the new page nests under its source"
key b command; sleep 3.5
mark "map"
key k command; sleep 3.5
key escape; sleep 2
mark "end"
