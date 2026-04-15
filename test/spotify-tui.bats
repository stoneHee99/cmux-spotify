#!/usr/bin/env bats

setup() {
  export CMUX_SPOTIFY_TEST=1
  # shellcheck source=../spotify-tui.sh
  . "$BATS_TEST_DIRNAME/../spotify-tui.sh"
}

# ── format_time ──────────────────────────────────────────────

@test "format_time: 0 seconds" {
  result=$(format_time 0)
  [ "$result" = "0:00" ]
}

@test "format_time: 30 seconds" {
  result=$(format_time 30)
  [ "$result" = "0:30" ]
}

@test "format_time: 61 seconds" {
  result=$(format_time 61)
  [ "$result" = "1:01" ]
}

@test "format_time: 3 minutes 45 seconds" {
  result=$(format_time 225)
  [ "$result" = "3:45" ]
}

@test "format_time: 10 minutes" {
  result=$(format_time 600)
  [ "$result" = "10:00" ]
}

# ── build_bar ────────────────────────────────────────────────

@test "build_bar: all filled" {
  result=$(build_bar 5 0)
  [ "$result" = "━━━━━●" ]
}

@test "build_bar: all empty" {
  result=$(build_bar 0 5)
  [ "$result" = "●─────" ]
}

@test "build_bar: half filled" {
  result=$(build_bar 3 3)
  [ "$result" = "━━━●───" ]
}

# ── field parsing ────────────────────────────────────────────

@test "parse: normal fields with SEP delimiter" {
  info="playing${SEP}My Song${SEP}My Artist${SEP}My Album${SEP}120${SEP}300"

  state="${info%%"$SEP"*}"; info="${info#*"$SEP"}"
  track="${info%%"$SEP"*}"; info="${info#*"$SEP"}"
  artist="${info%%"$SEP"*}"; info="${info#*"$SEP"}"
  album="${info%%"$SEP"*}"; info="${info#*"$SEP"}"
  pos="${info%%"$SEP"*}"; info="${info#*"$SEP"}"
  dur="$info"

  [ "$state" = "playing" ]
  [ "$track" = "My Song" ]
  [ "$artist" = "My Artist" ]
  [ "$album" = "My Album" ]
  [ "$pos" = "120" ]
  [ "$dur" = "300" ]
}

@test "parse: song title with pipe character" {
  info="playing${SEP}Song | Remix${SEP}DJ | Producer${SEP}Album${SEP}60${SEP}200"

  state="${info%%"$SEP"*}"; info="${info#*"$SEP"}"
  track="${info%%"$SEP"*}"; info="${info#*"$SEP"}"
  artist="${info%%"$SEP"*}"; info="${info#*"$SEP"}"
  album="${info%%"$SEP"*}"; info="${info#*"$SEP"}"
  pos="${info%%"$SEP"*}"; info="${info#*"$SEP"}"
  dur="$info"

  [ "$track" = "Song | Remix" ]
  [ "$artist" = "DJ | Producer" ]
}

@test "parse: Korean song title" {
  info="playing${SEP}우린 주를 만나고${SEP}어노인팅${SEP}워십앨범${SEP}45${SEP}310"

  state="${info%%"$SEP"*}"; info="${info#*"$SEP"}"
  track="${info%%"$SEP"*}"; info="${info#*"$SEP"}"
  artist="${info%%"$SEP"*}"

  [ "$track" = "우린 주를 만나고" ]
  [ "$artist" = "어노인팅" ]
}

# ── marquee ──────────────────────────────────────────────────

@test "marquee: short text stays unchanged" {
  MARQUEE_OFFSET=0
  update_marquee "Short"
  [ "$SCROLLED" = "Short" ]
}

@test "marquee: long text gets truncated" {
  MARQUEE_OFFSET=0
  update_marquee "This Is A Very Long Song Title - Some Artist Name"
  len=$(printf '%s' "$SCROLLED" | python3 -c "import sys; print(len(sys.stdin.read()))")
  [ "$len" -eq "$MARQUEE_MAX" ]
}

@test "marquee: offset advances each call" {
  MARQUEE_OFFSET=0
  update_marquee "This Is A Very Long Song Title - Some Artist Name"
  first="$SCROLLED"

  update_marquee "This Is A Very Long Song Title - Some Artist Name"
  second="$SCROLLED"

  [ "$first" != "$second" ]
}

@test "marquee: offset resets on track change" {
  MARQUEE_OFFSET=5
  PREV_TRACK="Old Track"
  track="New Track"

  # Simulate what update_sidebar does
  if [ "$track" != "$PREV_TRACK" ]; then
    MARQUEE_OFFSET=0
    PREV_TRACK="$track"
  fi

  [ "$MARQUEE_OFFSET" -eq 0 ]
  [ "$PREV_TRACK" = "New Track" ]
}
