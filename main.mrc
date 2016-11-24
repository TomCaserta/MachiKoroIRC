;; Created by Tom Caserta
;; Hawkee: [Plornt]
alias sanitizeInput {
  ;; TODO: Sanitation that requires no max length 
  ;return $1-
 ; echo -a [Sanitizing] $1-
  return $!decode( $encode($1-,m) ,m)
}

alias execIdentifier {
  var %params $null
  var %i 2 
  while (%i <= $0) {
    var %params = $iif(%params,$v1 $+ $chr(44),$null) $+ $sanitizeInput($($+($,%i),2))
    inc %i
  }
  return $($+($,$1,$iif(%params,( $+ %params $+ ), $null)),2)
}

; $1 = Channel, $2 = Section, $3 = Item, $4- = Value
alias mwrite {
  if ($3 == waitingFor) {
    ;echoa -a $1 3Info: Waiting for is $4
  }
  if ($3 == waitingFor && $4 < 0) {
    msg $1 4DEBUG: Command has gone into negatives? 
  }
  ;echo -a 03Write:  machikoro.ini $+($1,$chr(44),$2) $3 $4-
  writeini machikoro.ini $+($1,$chr(44),$2) $3 $4-
}

;; $1 == Channel $2 = Section $3 = Optional Item Only
alias mRemoveSectionStartingWith {
  var %i 1
  var %iniSecs = $ini(machikoro.ini, 0)
  var %builtWildCard $1 $+ $chr(44) $+ $2
  while (%i <= %iniSecs) {
    var %section = $ini(machikoro.ini, %i)
    echo -a %i -- %iniSecs -- %section --  %builtWildCard --- $3
    if ($startsWith(%section, %builtWildCard)) {
      mremove $1 $gettok(%section,2-,44) $3!
      dec %i
      dec %iniSecs
    }
    inc %i
  }
}

; $1 = Channel, $2 = Section, $3 = Item
alias mremove {
  ;msg $1 REMOVING $2 ( $3 )
  ;echo -a Removing $+($1,$chr(44),$2) $3
  remini machikoro.ini $+($1,$chr(44),$2) $3
}

alias mini {
  return $ini(machikoro.ini, $+($1,$chr(44),$2), $3)
}

; $1 = Channel, $2 = Section, $3 = Item, $4 = Ini File, $5- = Value
alias miniwrite {
  writeini $4 $+($1,$chr(44),$2) $3 $5-
}

; $1 = Channel, $2 = Section, $3 = Item
alias mread {
  return $readini($iif($4,$4,machikoro.ini), n, $+($1,$chr(44),$2), $3)
}

alias b { 
  return  $+ $1- $+ 
}

;; $1 == Channel $2 == Index
alias getTurnOffsetPlayer {
  echo -a Current Turn: $getTurn($1) Index $2 Next turn: $getTurn($1, $calc($mGetSetting($1, turn) + 1))
  return $getTurn($1, $calc($calc($calc($mGetSetting($1, turn) + $calc($2 - 1)) % $playerAmount($1)) + 1))
}

; 1 = Channel, $2 = alias to be called each time with %i and value
alias mForEachPlayer {
  var %iniFile $iif($4,$v1,machikoro.ini)
  var %i 1
  var %ini $ini(%iniFile, $+($1,$chr(44),players), 0)
  while (%i <= $playerAmount($1)) {
    $2 $getTurnOffsetPlayer($1, %i)
    inc %i
  }
}


; 1 = Channel, $2 = Section, $3 = alias to be called each time with %i and value
alias mForEach {
  var %iniFile $iif($4,$v1,machikoro.ini)
  var %i 1
  var %ini $ini(%iniFile, $+($1,$chr(44),$2), 0)
  while (%i <= %ini ) {
    var %currKey $ini(%iniFile, $+($1,$chr(44),$2), %i)
    var %currValue = $mread($1,$2,%currKey, %iniFile)
    $3 %currKey %currValue %i
    inc %i
  }
}


alias mIsInitializing {
  return $iif($mGetSetting($1,status) == 1,$true,$false)
}

alias mIsStarted {
  return $iif($mGetSetting($1, status) == 2, $true,$false)
}

alias mInitGame {
  mSetSetting $1 status 1
  initializeCards $1 $2-
}

alias mStartGame {
  incTurn $1
  mGiveStartingCardsAndMoney $1 
  mSetSetting $1 status 2
  nextTurn $1 init
}

alias mIsJoined {
  return $iif($mread($1, players, $2) == true,$true,$false)
}

alias machiJoin {
  mwrite $1 players $2 true
}

alias mGetSetting {
  return $mread($1, gameSettings, $2)
}

alias mSetSetting {
  mwrite $1 gameSettings $2 $3-
}

alias cardSectionIgnored {
  return $iif($1 == card_types || $1 == handler_priority,$true,$false)
}

alias translateCard {
  var %channel = $1
  var %card = $2-
  ;msg $1 %card
  if (%card !isnum && $ini(machi_cards.ini, %card, 0) > 0) {
    return %card
  }   
  elseif ($mread(%channel, temp_card_reverse, $md5($lower(%card))) != $null) {
    ; msg $1 Got this from md5 %card $lower(%card)  $md5($lower(%card)) $mread(%channel, temp_card_reverse, $md5($lower(%card)))
    return $mread(%channel, temp_card_reverse, $md5($lower(%card)))
  }

  var %i = 1
  var %potential $null
  while (%i <= $ini(machi_cards.ini,0) ) {
    var %section = $ini(machi_cards.ini,%i)
    if (!$cardSectionIgnored(%section)) {
      echo -a * $+ %card $+ * iswm $readCard(%section, name) 
      if (* $+ %card $+ * iswm $readCard(%section, name)) {
        echo -a IS POTENTIAL.... %card %section
        var %potential $addtok(%potential,%section, 44)
      }
    }
    inc %i
  }
  if ($numtok(%potential, 44) == 1) {
    return %potential
  } 
  return $null
}

; $1 = Card Name, $2 = Property
alias readCard {
  ;echo -a 2INFO: Reading card $1 property $2
  return $readini(machi_cards.ini,$1,$2)
}

alias playerSection {
  return player. $+ $1
}

alias getPlayerSetting {
  return $mread($1,$playerSection($2),$3)
}

alias setPlayerSetting {
  mwrite $1 $playerSection($2) $3 $4-
}
alias incPlayerSetting {
  setPlayerSetting $1 $2 $3 $calc($iif($getPlayerSetting($1,$2,$3),$v1,0) + $4)
}
alias addCoins {
  incPlayerSetting $1 $2 coins $3
}
alias getCoins {
  return $getPlayerSetting($1,$2,coins)
}
alias getCoinsFmt {
  return $coinage($getCoins($1,$2))
}
alias getPlayerCardAmount {
  return $iif($getPlayerSetting($1, $2, card. $+ $3),$v1,0)
}

;; $1 = Channel $2 = Player $3 = Card
alias removePlayerCard {
  incPlayerSetting $1 $2 card. $+ $3 -1
}
;; $1 = Channel $2 = Player $3 = Card
alias addPlayerCard {
  incPlayerSetting $1 $2 card. $+ $3 1
}
alias mTheme {
  return 10
}
alias mNoticeTheme {
  return 07
}
alias machiNotice {
  noop $dll(spaces.dll, send, NOTICE $1 $mTheme $+ $iif($isid && $3 == $true,$replace(2,$chr(32),.),$2-))
  echo $1 $timestamp <NOTICE: $+ $me $+ > $2-
}
alias machiMessage {
  noop $dll(spaces.dll, send, PRIVMSG $1 $mTheme $+ $iif($isid && $3 == $true,$replace(2,$chr(32),.),$2-))
  echo $1 $timestamp < $+ $me $+ > $2-
}
alias cardName {
  ;echo -a machi_cards.ini , card_types $readCard($1,type) $+ _icon
  return $+(,$readCard($1,color),$iif(!$2,$+([,$readini(machi_cards.ini,card_types,$readCard($1,type) $+ _icon),]),$null),$chr(32),$readCard($1,name),$mTheme)
}
alias playerAmount {
  return $mini($1, players, 0)
}
alias coinage {
  return $iif($2,$,💰) $+ $bytes($iif($1,$1,0),b)
}

alias getTypeName {
  return $readini(machi_cards.ini,card_types,$1 $+ _name)
}

;; $1 = Channel, $2 = Card, $3 = Amount per, $4 = Player, $5 = Multiplier Type
alias addCoinsPerCardWithMultiplierType {
  var %cardAmtMultiplierCard = $getPlayerCardAmount($1,$4,$2)
  if (%cardAmtMultiplierCard > 0) {
    var %cardTypesOfMultiplier = $mread($1,temp_card_types,$5)
    ;msg $1 Debug: %cardamtMultiplierCard  %cardTypesOfMultiplier
    var %i 1
    var %multiplier = 0
    while (%i <= $numtok(%cardTypesOfMultiplier,44)) {
      var %card = $gettok(%cardTypesOfMultiplier,%i,44)
      var %cardAmt = $getPlayerCardAmount($1,$4,%card)
      if (%cardAmt > 0) {
        var %multiplier = $calc(%multiplier + %cardAmt)
        var %names = $sentencify(%names,$cardName(%card) $chr(91) $+ x $+ %cardAmt $+ ])
      }
      inc %i
    }
    var %coinAmount = $calc($calc($3 * %multiplier) * %cardAmtMultiplierCard)
    addCoins $1 $4 %coinAmount
    machiNotice $4 Your %cardAmtMultiplierCard $cardName($2) just earned you $coinage(%coinAmount) from your $b($getTypeName($5)) cards ( $+ %names $+ )
  }
}
;; $1 = Channel, $2 = Card, $3 = Amount per, $4 = Player
;; #stopbeingannoying wheat_field 1 TomM Amount of cards: 0
alias addCoinsPerCard {
  var %cardAmt $getPlayerCardAmount($1,$4,$2)
  ;machiMessage $1 Debug: adding coins per card: $1 $2 $3 $4 Amount of cards: %cardAmt
  if (%cardAmt > 0) {
    var %amt $calc(%cardAmt * $3) 
    var %eventID $createEvent($1, onBeforeEarnCoin)
    var %oldAmt %amt
    noop $setEventValues($1, %eventID, $false, roller $4, cardOwner $4, coinAmount %amt, card $2, cardAmount %cardAmt, dispatcher addCoinsPerCard)
    var %continue $dispatchEvent($chan, %eventID, $true)
    var %isHandled = $eventInfo($1, %eventID).isHandled
    var %amt = $eventInfo($1, %eventID).coinAmount
    ;msg $1 0,07Debug: $eventInfo($1, %eventID).coinAmount VS %oldAmt
    destroyEvent $1 %eventID

    if (%continue) {
      addCoins $1 $4 %amt
      machiNotice $4 Your %cardAmt $cardName($2) card(s) just earned you $coinage(%amt) coins.
    }
  }
}

;; $1 = Channel $2 = Card $3 = Payer $4 = amount per, $5 = Player
alias payUserPerCard {
  if ($3 != $5) {
    var %cardAmt $getPlayerCardAmount($1,$5,$2)
    if (%cardAmt > 0) {
      var %amt = $calc(%cardAmt * $4) 

      var %eventID $createEvent($1, onBeforeEarnCoin)

      noop $setEventValues($1, %eventID, $false, roller $3, cardOwner $5, coinAmount %amt, card $2, cardAmount %cardAmt, dispatcher payUserPerCard)
      var %continue $dispatchEvent($chan, %eventID, $true)
      var %isHandled = $eventInfo($1, %eventID).isHandled
      var %amt = $eventInfo($1, %eventID).coinAmount

      destroyEvent $1 %eventID
      var %userCoins $getCoins($1, $3)
      var %origAmount %amt
      var %notEnoughCoins $iif(%userCoins >= %amt, $false, $true)
      var %amt = $iif(%notEnoughCoins, %userCoins, %amt)

      if (%continue) {
        addCoins $1 $3 $calc(0 - %amt)
        addCoins $1 $5 %amt
        machiNotice $3 Your roll cost you $coinage(%amt) to $5 $+ 's %cardAmt * $cardName($2) $+ . $&
          $iif(%notEnoughCoins, You didn't have enough to pay the full amount of $b(%origAmount), $null)


        machiNotice $5 Your %cardAmt $cardName($2) just earned you $coinage(%amt) from $3 $+ . $iif(%notEnoughCoins, They didn't have enough to pay the full amount of $b(%origAmount), $null)

        machiMessage $1 $b($3) just paid $b($5) $coinage(%amt) coins for their $cardName($2)
      }

    }
  }
}
;; $1 = Channel, $2 = Payee, $3 = Amount, $4 = Card Name, $5 = Player
alias payUser {
  if ($2 != $5) {
    var %amt $iif($3 > $getCoins($1, $5),$v2, $v1)

    addCoins $1 $2 %amt
    addCoins $1 $5 $calc(0 - %amt)

    machiNotice $2 Your $cardName($4) just earned you $coinage(%amt) from $b($5)
    machiNotice $5 $b($2) just took $coinage(%amt) due to their $cardName($4) activating.
  }
}
;; HANDLERS 
;; Input: $1 = Channel $2 = Roller $3 = Card Name

alias MachiKoro_BlueCardHandler {
  ;  machimessage $1 DEBUG: Debugging blue card handler: $1 $2 $3
  var %amount = $readCard($3, receive)
  noop $mForEach($1,players,addCoinsPerCard $1 $3 %amount) 
  return $false
}
alias MachiKoro_GreenCardHandler {
  var %amount = $readCard($3, receive)
  var %multiplierType = $readCard($3, multiplier)
  if (%multiplierType != $null) {
    addCoinsPerCardWithMultiplierType $chan $3 %amount $2 %multiplierType
  }
  else {
    addCoinsPerCard $chan $3 %amount $2
  }
  return $false
}
alias MachiKoro_RedCardHandler {
  var %amount = $readCard($3, receive)
  noop $mForEachPlayer($1, payUserPerCard $1 $3 $2 %amount) 
  return $false
}
alias MachiKoro_StadiumHandler {

  if ($getPlayerCardAmount($1,$2,$3) > 0) {
    var %amt = $readCard($3,receive)
    noop $mForEachPlayer($1, players, payUser $1 $2 %amt $3)
    return $false
  }
}
alias MachiKoro_BusinessCenterHandler {
  ;msg $1 Bus center called $1-
  if ($getPlayerCardAmount($1,$2,$3) > 0) {
    machiMessage $1 $2 $+ 's $cardName($3) has just been activated. $2 please use !takeCard [user] [Card Name]
    ;'
    registerCommand $1 $2 takeCardHandler !takeCard 
    return $true
  }
}


;; $1 = Channel, $2 = User, $3- = Content
;; Returns $true for valid, $false for invalid
alias takeCardHandler {
  var %chan $1
  var %nick $2
  if ($3) {
    var %user = $gettok($3,1,32)
    var %card = $translateCard($1,$gettok($3,2-,32))
    if (!%card || $readCard(%card, type) == 8) {
      machiMessage $1 You must specify a non landmark card to take $b($2) using $b(!takeCard <user> <card>)
      return $false
    }

    if ($mIsJoined($1, %user)) {
      var %hasCard $getPlayerCardAmount($1, %user, %card)
      if (%hasCard > 0) {
        removePlayerCard $1 %user %card
        addPlayerCard $1 $2 %card 
        machiNotice $2 Taken $cardName(%card) from $b(%user)
        machiNotice %user $b($2) just took $cardName(%card) from you because of their $cardName(business_center) establishment.
        machiMessage $1 $b($2) took $cardName(%card) from $b(%user) $+ !
        return $true
      }
      else {
        machiNotice $2 $b(%user) does not have that card. 
      }
    }
    else {
      machiNotice $2 You didnt correctly supply a correct user to take a card from. Make sure they're in the current game and use $b(!takeCard <nickname> <card>)
    }
  }
  return $false
}

alias MachiKoro_TVStationHandler {

  if ($getPlayerCardAmount($1,$2,$3) > 0) {
    machiMessage $1 $2 $+ 's $cardName($3) has just been activated. $2 please use !takeCoins [player] 
    ;'
    registerCommand $1 $2 takeCoinsHandler !takeCoins
    return $true
  }
}

;; $1 = Channel, $2 = User, $3- = Content
;; Returns $true for valid, $false for invalid
alias takeCoinsHandler { 
  var %chan $1
  var %nick $2
  if ($3) {
    var %user = $gettok($3,1,32)
    if ($mIsJoined($1, %user)) {
      var %userCoins $getCoins($1, %user)
      var %takeCoins $iif(%userCoins > 5, 5, $iif(%userCoins > 0,$v1,0))
      addCoins %chan %nick %takeCoins
      addCoins %chan %user $calc(0 - %takeCoins)
      machiNotice $2 Taken $coinage(%takeCoins) from $b(%user) $+ $iif(%takeCoins == 5,.,$chr(32) $+ as they didnt have enough to cover the costs.)
      machiNotice %user $b($2) just took $coinage(%takeCoins) from you because of their $cardName(tv_station) establishment.
      machiMessage $1 $b($2) took $coinage(%takeCoins) from $b(%user) $+ .
      return $true
    }
    else {
      machiNotice $2 You didnt correctly supply a correct user to take coins from. Make sure they're in the current game and use $b(!takeCoins [nickname])
    }
  }
  return $false
}

;; Event Handlers 
;; $1 = Channel $2 = Event ID
;; Returns prevent default

alias MachiKoro_ShoppingMallHandler {
  var %cardOwner $eventInfo($1, $2).cardOwner
  var %roller $eventInfo($1, $2).roller
  var %coinAmount $eventInfo($1, $2).coinAmount
  var %cardAmount $eventInfo($1, $2).cardAmount
  var %card $eventInfo($1, $2).card
  var %dispatcher $eventInfo($1, $2).dispatcher
  var %type $readCard(%card, type)

  if (%type == 4 || %type == 7) {
    if ($getPlayerCardAmount($1, %cardOwner, shopping_mall) > 0) {
      ;noop $setEventValues($1, %eventID, $false, roller $3, cardOwner $5, coinAmount %amt, card $2, cardAmount %cardAmt, dispatcher payUserPerCard)

      $setEventValues($1, $2, $false, coinAmount $calc($calc($readCard(%card, receive) + 1) * %cardAmount))
      ;

      machiNotice %cardOwner Your $cardName(shopping_mall) just activated earning $coinage(1) more for each $cardName(%card) you own. 
    }
  }
}

alias MachiKoro_StationHandler {
  var %nick = $eventInfo($1, $2).nick
  var %diceCount = $gettok($eventInfo($1,$2).message,2,32)
  if ($getPlayerCardAmount($1, %nick, station) > 0) {
    noop $setEventValues($1, $2,$true, fromStation $true)
    if (%diceCount isnum && %diceCount <= 2 && %diceCount > 0) {
      noop $setEventValues($1, $2,$true,isHandled $true)

      machiMessage $1 $b(%nick) is rolling $b(%diceCount) $iif(%diceCount == 1,die,dice) $+ . 
      mRoll $1 %nick %diceCount

    }
    else {
      noop $setEventValues($1, $2,$true,isHandled $false)
      machiMessage $1 Sorry $b(%nick) $+ , as you have a $cardName(station) you need to specify the amount of dice you would like to roll.
    }
  }
}

alias MachiKoro_AmusementParkHandler {
  var %eventName = $eventInfo($1, $2).eventName
  ;  msg $1 RETAKING TURN %eventName 
  if (%eventName == onAfterDiceRoll) {
    var %nick = $eventInfo($1, $2).nick
    ; msg $1 %nick was the caller
    var %diceCounts = $eventInfo($1, $2).diceCounts
    if ($getPlayerCardAmount($1, %nick, amusement_park) > 0 && ($eventInfo($1, $2).isHandled == $false )) {
      if ($numtok(%diceCounts,44) > 1) {
        var %i 2
        ; machiMessage $1 Debug dice counts : %diceCounts
        var %prev $gettok(%diceCounts,1,44)
        while (%i <= $numtok(%diceCounts,44)) {
          var %curr = $gettok(%diceCounts, %i, 44)
          if (%prev != %curr) {
            ;  machiMessage $1  %prev is not equal to %curr
            return 
          }
          var %prev = %curr
          inc %i
        }

        ; All dice are the same...
        mSetSetting $1 retakeTurn $true
        machiMessage $1 $b(%nick) just rolled a double! They can have another turn at the end of this because of their $cardName(amusement_park)
      }
    }
  }
  else if (%eventName == onTurnEnd) {
    if ($mGetSetting($1,retakeTurn) == $true) {
      mSetSetting $1 retakeTurn $false
      machiMessage $1 Retaking turn as they rolled a double...
      decTurn $1
    }
  }
}


;; $1 = Channel, $2 = User, $3- = Content
;; Returns $true for valid, $false for invalid
alias MachiKoro_ReRollHandler {
  setPlayerSetting $1 $2 rerolled $true
  var %eventID $createEvent($1, onBeforeDiceRoll)
  noop $setEventValues($1, %eventID, $false, nick $2, message !roll $3-)
  var %continue $dispatchEvent($chan, %eventID, $true)
  var %isHandled = $eventInfo($1, %eventID).isHandled
  destroyEvent $1 %eventID

  if (%continue) {
    deRegisterCommand $1 $2 !continue
    var %roll = $rand(1,6)
    mRoll $1 $2 1
    setPlayerSetting $1 $2 rerolled $false
    return $true
  }
  else if (%isHandled == $true) {
    deRegisterCommand $1 $2 !continue

    setPlayerSetting $1 $2 rerolled $false
    return $true
  }
  setPlayerSetting $1 $2 rerolled $false
  return $false
}

;; $1 = Channel, $2 User, $3- = Content
alias MachiKoro_PurchaseHandler {
  var %card $translateCard($1,$3-)
  if (!%card) {
    machiMessage $1 $b($2) $+ , that card does not exist or you didnt specify the card correctly. Please use $b(!purchase <card>) $+ . You can also $b(!pass) if you want to end your turn.
    return $false
  }
  var %coinAmount $readCard(%card, cost) 
  if (%coinAmount > $getCoins($1, $2)) {
    machiMessage $1 $b($2) $+ , you do not have enough coins to purchase the $cardName(%card) $+ , you require $b($coinage(%coinAmount)) $+ . You can also $b(!pass) if you want to end your turn.
    return $false
  }
  var %cardsLeft $getMarketAmount($1, %card)

  if (%cardsLeft != unlimited && %cardsLeft <= 0) {
    machiMessage $1 $b($2) $+ , sorry there is no more of that establishment on the market. You can also $b(!pass) if you want to end your turn. 
    return $false
  }

  if ($cannotBuyCard($1, $2, %card)) {
    machiMessage $1 $b($2) $+ , sorry you cannot purchase this card because: $cantBuyReason($v1) $+ . You can also $b(!pass) if you want to end your turn.
    return $false
  }

  setPlayerSetting $1 $2 hasPurchasedCard $true
  addCoins $1 $2 $calc(0 - %coinAmount)
  addPlayerCard $1 $2 %card 
  removeCardFromMarket $1 %card
  machiMessage $1 $b($2) just purchased the $cardName(%card) for $coinage(%coinAmount) $+ $iif(%cardsLeft != unlimited,$chr(44) there is now $b($calc(%cardsLeft - 1)) left on the market.,.)

  return $true
}

alias MachiKoro_PassHandler {
  mremove $1 commands. $+ $2
  mSetSetting $1 waitingFor 0
  machimessage $1 $b($2) passed the rest of their turn.
  return $true
}

;; $1 = Channel, $2 = User, $3- = Content
;; Returns $true for valid, $false for invalid
alias MachiKoro_ContinueRollHandler {
  var %dice $getPlayerSetting($1,$2,radioTower_eventDice)
  var %diceCounts $getPlayerSetting($1,$2,radioTower_eventDiceCounts)
  var %diceTotal $getPlayerSetting($1,$2,radioTower_eventDiceTotal)
  var %diceMessage $getPlayerSetting($1,$2,radioTower_eventDiceMessage)
  machiMessage $1 Continuing with %diceMessage %isHandled

  setPlayerSetting $1 $2 rerolled $true
  var %eventID $createEvent($1, onAfterDiceRoll)
  noop $setEventValues($1, %eventID, $false, nick $2, dice %dice, diceCounts %diceCounts, diceTotal %diceTotal, diceMessage %diceMessage)
  var %continue = $dispatchEvent($1, %eventID)
  deRegisterCommand $1 $2 !roll
  if (%continue) {

    processRoll $1 %diceTotal $2
    ;machiMessage $1 Debug: Total %diceTotal $2 $1 %dice %diceCounts %diceTotal %diceMessage
    setPlayerSetting $1 $2 rerolled $false
    return $true
  }
  return $true
}

alias MachiKoro_RadioTowerHandler {
  var %nick = $eventInfo($1, $2).nick
  if ($getPlayerCardAmount($1, %nick, radio_tower) > 0) {
    if ($getPlayerSetting($1, %nick, rerolled) != $true) {
      registerCommand $1 %nick MachiKoro_ReRollHandler !roll
      registerCommand $1 %nick MachiKoro_ContinueRollHandler !continue
      setPlayerSetting $1 %nick rerolled $false
      setPlayerSetting $1 %nick radioTower_eventDice $eventInfo($1,$2).dice 
      setPlayerSetting $1 %nick radioTower_eventDiceCounts $eventInfo($1,$2).diceCounts
      setPlayerSetting $1 %nick radioTower_eventDiceTotal $eventInfo($1,$2).diceTotal
      setPlayerSetting $1 %nick radioTower_eventDiceMessage $eventInfo($1,$2).diceMessage 
      noop $setEventValues($1, $2, $true, isHandled $true)
      machiMessage $1 $b(%nick) as you have a $cardName(radio_tower) you have the option of discarding your roll by $b(!roll) again or $b(!continue)
    }
  }
}

;; END HANDLERS 

;; $1 = Channel, $2 = Player, $3 = Handler, $4 = Command, $5 = Do not wait for command
alias registerCommand {
  if ($mread($1, commands. $+ $2, $4) == $null) {
    mwrite $1 commands. $+ $2 $4 $3
    if (!$5) {
      ;  msg $chan 2Debug: Setting waiting for for $4 as $5 is true. 
      mSetSetting $1 waitingFor $calc($mGetSetting($1,waitingFor) + 1)
    }
  }
}

;; $1 = Channel, $2 = Player, $3 = Command $4 = Do not wait for command
alias deRegisterCommand {
  if ($mread($1, commands. $+ $2, $3) != $null) {
    mremove $1 commands. $+ $2  $3
    if (!$4) {
      ;  msg $chan 2Debug: Setting waiting for for $3 as $4 is true. 
      mSetSetting $1 waitingFor $calc($mGetSetting($1,waitingFor) - 1)
    }
  }
}


; $1 = Channel $2 = Roller $3 = card name
; returns true or false if a player interaction is required
alias handleCard {
  echo -a Handling card: $1-
  return $execIdentifier($readCard($3,handler),$1,$2,$3)
}

; $1 = Channel, $2 = roll, $3 = player nick, [$4 = Skip to handlerIndex, $5 = Skip to cardIndex]
alias processRoll {
  var %hitCards = $mread($1,temp_card_rolls,$2)
  ;msg $1 DEBUG: $1 $2 $3
  ;msg $1 Debug Hit Cards: %hitCards
  if (%hitCards) {
    var %processIndex = 1
    var %hasSkipped = $false
    if ($4) {
      var %processIndex = $4
    }
    while (%processIndex <= $ini(machi_cards.ini, handler_priority, 0)) {
      var %handlerSection = $ini(machi_cards.ini, handler_priority, %processIndex)
      var %handler = $readini(machi_cards.ini, handler_priority, %handlerSection)
      var %handlerCards = $mread($1, temp_card_handlers, %handler)
      var %i = 1
      echo -a Debug: %handler ::: %handlerCards

      if ($5 && %hasSkipped == $false) {
        var %hasSkipped = $true
        var %i = $5
      }

      while (%i <= $numtok(%hitCards,44) ) {
        var %hitCard $gettok(%hitCards,%i,44)
        if ($istok(%handlerCards, %hitCard, 44)) {
          if ($handleCard($1,$3,%hitCard)) {
            var %waitingFor = $iif(%waitingFor,%waitingFor $+ $chr(44),$null) $+ %hitCard
            mPauseProcessing $1 %processIndex $calc(%i + 1) $3 $2
            return 
          }
        }
        inc %i
      }
      inc %processIndex
    }
  }
  if (!%waitingFor && $getPlayerSetting($1, $3, hasPurchasedCard) == $false) {
    if ($getCoins($1,$3) > 0) {
      var %waitingFor = $iif(%waitingFor, %waitingFor $+ $chr(44),$null) $+  MachiKoro_PurchaseHandler
      ;; This var is pointless above? No idea. Fuck it.
      machiMessage $1 $b($3) you can now purchase a card from the market with $b(!purchase <card>) $+ , or just $b(pass)
      sendMarket $1 $3 
      registerCommand $1 $3 MachiKoro_PurchaseHandler !purchase

    }
    else {
      machiMessage $1 $b($3) You have no coins to purchase anything... Moving on.
    }
  }
  if (!%waitingFor) {
    nextTurn $1
  }
}

alias isProcessingPaused {
  return $iif($mGetSetting($1, pausedProcessing) == $true,$true,$false)
}

alias mPauseProcessing {
  machiMessage $1 MachiKoro is paused whilst $b($4) makes their move!
  mSetSetting $1 pausedProcessing $true
  mSetSetting $1 currentHandlerID $2
  mSetSetting $1 currentHandlerIndex $3
  mSetSetting $1 currentRoller $4
  mSetSetting $1 currentRoll $5
}

alias mResumeProcessing {
  mSetSetting $1 pausedProcessing $false
  processRoll $1 $mGetSetting($1, currentRoll) $mGetSetting($1, currentRoller) $mGetSetting($1, currentHandlerID) $mGetSetting($1, currentHandlerIndex)
  mSetSetting $1 currentHandlerID 1
  mSetSetting $1 currentHandlerIndex 1
  mSetSetting $1 currentRoller -
  mSetSetting $1 currentRoll 0
}

alias getTurn {
  return $mini($1, players, $iif(!$2,$mGetSetting($1,turn),$2))
}
alias incTurn {
  ; msg $1 DEBUG Players:  $playerAmount($1) Curr Turn: $getTurn($1) incrementing by 1 is: $calc($mGetSetting($1,turn) + 1) :: ACT TURN $iif($calc($mGetSetting($1,turn) + 1) <= $playerAmount($1),$v1,1)
  var %turn = $iif($calc($mGetSetting($1,turn) + 1) <= $playerAmount($1),$v1,1)
  mSetSetting $1 turn %turn
}

alias decTurn {
  var %turn = $iif($calc($mGetSetting($1,turn) - 1) > 0,$v1,$playerAmount($1))
  mSetSetting $1 turn %turn
}

;; $1 chan $2 player
alias sendCoins {

  machiNotice $2 Coin amounts after that turn: $getPlayerCoins($1)
}

alias eachGiveCard {
  ;echo -a Giving card $1-
  addPlayerCard $1 $3 $2
}
alias eachGiveCoins {
  addCoins $1 $3 $2
}

alias mGiveStartingCardsAndMoney {
  var %i 1
  noop  $mForEach($1,players,eachGiveCoins $1 3 )
  while (%i <= $ini(machi_cards.ini,0) ) {
    var %section = $ini(machi_cards.ini,%i)
    if (!$cardSectionIgnored(%section)) {
      ;echo -a %SECTION = $readCard(%section, start_with)
      if ($readCard(%section, start_with) == 1) {

        noop  $mForEach($1,players,eachGiveCard $1 %section ) 
      }
    }
    inc %i
  } 

}


alias masssendCoins {
  noop  $mForEach($1,players,sendCoins $1 $2) 
}
alias masssendCardInfo {
  noop  $mForEach($1,players,sendCardInfo $1 $2) 

}
alias nextTurn {
  ;echo -a 07Debug: Next turn called with $1-
  if ($hasWon($1, $getTurn($1))) {
    machiMessage $1 $b($getTurn($1)) has collected all the required establishments and has won the game!
    mreset $1
  }
  else {

    deRegisterCommand $1 $getTurn($1) !pass $true
    ;echo -a 07Debug: Waiting for $mGetSetting($1,waitingFor) process to complete before moving to next turn.
    if (!$mGetSetting($1,waitingFor) || $mGetSetting($1,waitingFor) <= 0) {
      incTurn $1
      ;echo -a 07Debug: Turn is currently $getTurn($1)

      var %eventID $createEvent($1, onTurnEnd)
      noop $setEventValues($1, %eventID, $false, nick $getTurn($1))
      var %continue = $dispatchEvent($1, %eventID)

      ;echo -a 07Debug: Turn after event is $getTurn($1)

      if (%continue) {

        setPlayerSetting $1 $getTurn($1) hasPurchasedCard $false
        setPlayerSetting $chan $nick hasRolled $false
        registerCommand $1 $getTurn($1) MachiKoro_PassHandler !pass $true
        ;echo -a 07Debug: Registering event handlers for next turn.
        if ($2 == init) {
          ;echo -a 07Debug: Initialized from start game.
          masssendCardInfo $1 
          machiMessage $1 MachiKoro has just started. $b($getTurn($1)) $+ 's turn. Type $b(!roll) to begin or type $b(!pass) to pass your turn.
        }
        else {
          masssendCoins $1 
          machiMessage $1 That's their turn over. Next up is $b($getTurn($1)) $+ ! Type $b(!roll [dice]) to roll or type $b(!pass) to pass your turn.
        }
      }
    }
    else {
      registerCommand $1 $getTurn($1) MachiKoro_PassHandler !pass $true
    }
  }
}

;; $1 = Channel, $2 = Nick
alias hasWon {
  var %i 1
  var %winCards $mGetSetting($1,win_cards)
  var %playerWinCards 0
  var %winCardAmount $numtok(%winCards,44)
  while (%i <= %winCardAmount) {
    var %currCard = $gettok(%winCards,%i, 44)
    if ($getPlayerCardAmount($1,$2,%currCard) > 0) {
      inc %playerWinCards
    }
    inc %i
  }
  if (%playerWinCards == %winCardAmount) {
    return $true
  }
  return $false
}


;; $1 = Channel, $2 = event ID $3 = prevent default $4- = [<property> <value> ...]
alias setEventValues {
  if (!$isid) {
    ;echo -a 4Error: $!returnEventValues Must be called as an identifier to preserve spaces in tokenization
    halt
  }
  mwrite $1 event. $+ $2 preventDefault $3
  var %i 4
  while (%i <= $0) {
    var %currVal = $($+($,%i),2)
    mwrite $1 event. $+ $2 $gettok(%currVal,1-,32)
    inc %i
  }
}

;; $1 = Channel, $2 = Event ID
alias destroyEvent {
  mremove $1 event. $+ $2
}

;; $1 = Channel, $2 = Event Name
alias createEvent {
  if (!$isid) {
    ;echo -a 04Error: $!createEvent must be called as an identifier to return the event ID to be destroyed once processing is complete
    halt
  } 
  if (!$2) {
    ;echo -a 04Error: No event name provided
    halt
  }
  var %eventID $calc($mGetSetting($1,event_id) + 1)
  mSetSetting $1 event_id %eventID
  noop $setEventValues($1,%eventID,$false,eventName $2,createdAt $ctime, isHandled $false)
  return %eventID
}

;; $1 = Channel $2 event ID $prop = property
alias eventInfo {
  ;machinotice $1 $1 $2 $prop
  if ($prop) {
    return $mread($1, event. $+ $2, $prop)
  }
  return $2
}

;; $1 Channel, $2 event ID, $3 self destroy
alias dispatchEvent {
  var %listeners = $mread($1,temp_card_hooks,$eventInfo($1, $2).eventName)
  var %numListeners = $numtok(%listeners, 44)
  var %processIndex = 0
  var %continueProcessing = $true

  ;echo -a Dispatching event $1 : $2 to %listeners for event $eventInfo($1, $2).eventName
  while (%processIndex <= $ini(machi_cards.ini, handler_priority, 0)) {
    var %handlerSection = $ini(machi_cards.ini, handler_priority, %processIndex)
    var %handler = $readini(machi_cards.ini, handler_priority, %handlerSection)
    ;echo -a Checking event dispatchers %handlerSection %handler
    var %i 1
    while (%i <= %numListeners) {
      var %currListener = $gettok(%listeners, %i, 44)
      if ($readCard(%currListener,handler) == %handler) {
        noop $execIdentifier(%handler, $1, $2) 
        ;echo -a Prevent Default: $eventInfo($1, $2).preventDefault
        if ($eventInfo($1, $2).preventDefault == $true) {
          var %continueProcessing = $false
          ; machiMessage $1 Debug: Stopping event from propagating.
        }
      }
      inc %i
    }
    inc %processIndex
  }
  if (!$3 || $3 == $false) {
    noop $destroyEvent($1, $2)

  }
  return %continueProcessing
}

alias formatRolls {
  var %useRange = $false
  var %min $gettok($1,1,44)
  var %max $gettok($1,1,44)
  var %i 1
  while (%i <= $numtok($1,44)) {
    var %pRoll = $gettok($1, %i, 44)
    if (%pRoll < %min) {
      var %min = %pRoll
    }
    if (%pRoll > %max) {
      var %max = %pRoll
    }
    ;echo -a %pRoll curr num Min %min Max %max ::: $1-
    inc %i
  }
  var %diff $calc(%max - %min)
  if (%diff > 1) {
    var %x $calc(%min + 1)
    var %useRange = $true
    ;echo -a Diff is %diff
    while (%x < %max) {
      ;echo -a Debug X is %x
      if (!$istok($1,%x,44)) {
        %useRange = $false
        ;echo -a Not using range because $1 does not have %x in it $istok($1,%x,44)
      }
      inc %x
    }
  }
  else if (%diff == 1) {
    var %useRange $true
  }
  return $iif($2,$null,⚀) $+ $iif(%useRange,%min $+ ~ $+ %max,$1)
}

;; $1 = Card
alias formatCardRoll {
  ;echo -a 0,4DEBUG ROLL: $readCard($1,roll) $1 is card
  return $iif($readCard($1,roll),$+([,$formatRolls($v1,$2),]),$null)
}

;; $1 = Channel $2 = Card
alias formatCardAmount {

  var %marketAmount $getMarketAmount($1, $2)
  return $iif(%marketAmount != unlimited, $+($chr(91),x,%marketAmount,]),$null)
}

;; $1 = Card
alias formatCardCost {
  return $+([,$coinage($readCard($1,cost),$2),])
}


alias formatCardType {
  return $getTypeName($readCard($1, type))
}

;; $1 = Channel $2 = Card
alias formatCardMarket {
  var %ret $cardName($2) $formatCardAmount($1, $2) $formatCardCost($2) $formatCardRoll($2)
  if (!$cannotBuyCard($1,$3,$2)) {
    var %ret $b(%ret)
  }
  return %ret
}

alias formatCardReceive {
  return $iif($readCard($1, receive),$coinage($v1, $2),$null) 
}
alias padd {
  returnex $iif($3,$str($chr(32),$1),$null) $+ $2 $+ $iif(!$3,$str($chr(32),$1) $+ $b($chr(124)) $+ $chr(32),$null)
}
alias ds {
  remove machikoro.ini
  initializeCards $chan
  sendCardInfo $chan $1
}
alias slen {
  return $len($strip($1,cb))
}

alias lenp {
  returnex $padd($calc($1 + 5 - $2),$3)
}

alias isExtensionEnabled {
  return $iif($mGetSetting($1, extension. $+ $2) == $true,$true,$false)
}
alias enableExtension {
  msetsetting $1 extension. $+ $2 $true
}
alias disableExtension {
  msetsetting $1 extension. $+ $2 $false
}
alias sendCardInfo {
  var %i = 1
  var %cardOutput 
  var %maxLengthName $getMaxLength($1, name)
  var %maxLengthAmount $getMaxLength($1, amount)
  var %maxLengthCost $getMaxLength($1, cost)
  var %maxLengthRoll $getMaxLength($1, roll)
  var %maxLengthType $getMaxLength($1, type)
  var %maxLengthReceive $getMaxLength($1, receive)

  var %cardName = $getHeading(cn)
  var %cardType = $getHeading(t)
  var %cardReceives = $getHeading(i)
  var %cardAmount = $getHeading(a)
  var %cardCost = $getHeading(c)
  var %cardRoll = $getHeading(r)
  var %cNL $slen(%cardName)
  var %cTL $slen(%cardType)
  var %cRL $slen(%cardReceives)
  var %cAL $slen(%cardAmount)
  var %cCL $slen(%cardCost)
  var %cRoL $slen(%cardRoll)
  noop $machiMessage($2,$b($chr(124)) $+ $chr(32)  $+ $chr(32)  $+ $padd($calc(%maxLengthName - %cNL + 3),$b(%cardName)) $+ $padd($calc(%maxLengthAmount - %cAL + 3),$b(%cardAmount)) $+ $padd($calc(%maxLengthCost - %cCL + 3), $b(%cardCost)) $+ $padd($calc(%maxLengthRoll - %cRoL + 3), $b(%cardRoll)) $+ $padd($calc(%maxLengthReceive - %cRL + 3), $b(%cardReceives)) $+ $padd($calc(%maxLengthType - %cTL + 3), $b(%cardType)))

  while (%i <= $mini($1, temp_card_types, 0)) {
    var %type $mread($1, temp_card_types, $mini($1, temp_card_types, %i))
    var %x 1
    var %amtC $numtok(%type, 44)
    while (%x <= %amtC) {
      var %card = $gettok(%type, %x, 44)
      var %cardName $cardName(%card,$true)
      var %cNL $slen(%cardName)
      var %cardType $formatCardType(%card)
      var %cTL $slen(%cardType)
      var %cardReceives $formatCardReceive(%card, $true)
      var %cRL $slen(%cardReceives)
      var %cardAmount $formatCardAmount($1, %card)
      var %cAL $slen(%cardAmount)
      var %cardCost $formatCardCost(%card, $true)
      var %cCL $slen(%cardCost)
      var %cardRoll $formatCardRoll(%card, $true)
      var %cRoL $slen(%cardRoll)
      ;echo -a %maxLengthName %cNL %cardName
      var %message $b($chr(124)) $+ $chr(32) $+ $padd($calc(%maxLengthName - %cNL + 3),%cardName) $+ $padd($calc(%maxLengthAmount - %cAL + 3),%cardAmount) $+ $padd($calc(%maxLengthCost - %cCL + 3), %cardCost) $+ $padd($calc(%maxLengthRoll - %cRoL + 3), %cardRoll) $+ $padd($calc(%maxLengthReceive - %cRL + 3), %cardReceives) $+ $padd($calc(%maxLengthType - %cTL + 3), %cardType)
      noop $machiMessage($2,%message)
      var %desc $readCard(%card, description)
      var %descLen $slen(%desc)

      noop $machiMessage($2,$b($chr(124)) $+ $str($chr(32),2) $+ $padd($calc($slen(%message) - %descLen - 4), %desc))
      noop $machiMessage($2,$b($chr(124)) $+ $str(_,$calc($slen(%message) - 2)) $+ $b($chr(124)))
      inc %x 
    }
    var %cardOutput $null
    inc %i
  } 
}

;; $1 = Channel $2 = Target 
alias sendMarket {
  var %i = 1
  var %cardOutput 
  while (%i <= $mini($1, temp_card_types, 0)) {
    var %type $mread($1, temp_card_types, $mini($1, temp_card_types, %i))
    var %x 1
    var %amtC $numtok(%type, 44)
    while (%x <= %amtC) {
      var %card = $gettok(%type, %x, 44)
      var %cardOutput = $sentencify(%cardOutput,$formatCardMarket($1, %card, $2))
      inc %x
    }

    machiNotice $2 $b([Market]) %cardOutput
    var %cardOutput $null
    inc %i
  } 
  machiNotice $2 $b([Market]) You currently have $b($coinage($getCoins($1, $2))) to spend.
}

alias pluralizeDie {
  return $iif($1 > 1,dice,die)
}

alias dieIcon {
  return $gettok(⚀.⚁.⚂.⚃.⚄.⚅,$1,46)
}

;; $1 = Channel, $2 = Player, $3 = Amount of dice
alias mRoll {
  var %diceCounts $rand(1,6)
  var %diceMessage $dieIcon(%diceCounts) $b(%diceCounts)
  var %total %diceCounts
  ;echo -a 2INFO: Dice Total %total
  while ($numtok(%diceCounts,44) < $3) {
    var %curRoll $rand(1,6)
    ;; Cant use addtok for this as it doesnt allow for dupes
    var %diceCounts %diceCounts $+ , $+ %curRoll
    var %total = $calc(%total + %curRoll)
    var %diceMessage $sentencify(%diceMessage,$dieIcon(%curRoll) $b(%curRoll))
  }
  machiMessage $1 4 $+ $b($2) rolled %diceMessage with $3 $pluralizeDie($3)

  ; Dispatching event
  var %eventID $createEvent($1, onAfterDiceRoll)
  noop $setEventValues($1, %eventID, $false, nick $2, dice $3, diceCounts %diceCounts, diceTotal %total, diceMessage %diceMessage)
  var %continue = $dispatchEvent($1, %eventID)
  if (%continue) {
    ;;echo -a DEBUG ROLL: $1 %total $2
    processRoll $1 %total $2
  }
}

alias startsWith {
  ;echo -a $1 STARTS WITH $2 = $pos($1,$2)
  return $iif($pos($1,$2) == 1, $true, $false)
}

alias getMarketAmount {
  return $mGetSetting($1, market $+ . $+ $2)
}

;; $1 = Channel, $2 = Player, $3 = Card
alias cannotBuyCard {
  if ($readCard($3, allowed) != $null && $getPlayerCardAmount($1, $2, $3) >= $readCard($3, allowed)) {
    return 3
  }
  else  if ($getMarketAmount($1, $3) != unlimited && $getMarketAmount($1, $3) <= 0) {
    return 1
  }
  else if ($getCoins($1, $2) < $readCard($3, cost)) {
    return 2
  }
  else if ($3 == $null) {
    return 4
  }
  return 0
}

;; $1 = Status Code From $cannotBuyCard
alias cantBuyReason {
  if ($1 == 0) {
    return This establishment is purchasable
  }
  else if ($1 == 1) {
    return There is no more establishments of this type left on the market.
  }
  else if ($1 == 2) {
    return You do not have enough money for this establisment.
  }
  else if ($1 == 3) {
    return You already own the maximum allowed of this establishment type.
  }
  else if ($1 == 4) {
    return That card does not exist.
  }
}

;; $1 = Channel, $2 = Card, $3 = amount?
alias removeCardFromMarket {
  var %mAmt $getMarketAmount($1, $2)
  if (%mAmt != unlimited) {

    msetsetting $1 market. $+ $2 $iif($calc(%mAmt - $iif($3,$v1,1)) <= 0,0,$v1)

  }
}

;; $1 = Channel, $2 = Card, $3 = amount?
alias addCardToMarket {
  var %mAmt $getMarketAmount($1, $2)
  if (%mAmt != unlimited && $3 != unlimited) {
    msetsetting $1 market. $+ $2 $calc(%mAmt + $iif($3,$v1,1))
  }
  else {
    msetSetting $1 market. $+ $2 unlimited
  }
}



;; $1 = Channel, $2 = Player
alias mremovePlayer {
  if ($getTurn($1) == $2) {
    decTurn $1
  }
  var %i = 1

  var %playerSections = $mini($1, $playerSection($2), 0)
  while (%i <= %playerSections) {
    var %iniSec = $mini($1, $playerSection($2), %i)
    if ($startsWith(%iniSec, card.)) {
      var %card = $right(%iniSec, $len(card.))
      addCardToMarket $1 %card $getPlayerCardAmount($1, $2, %card)
    }
    inc %i
  }
  mremove $1 players $2
  mremove $1 player. $+ $2 

  machiMessage $1 $b($2) has been removed from the current game and all their cards have been added back to the market. It is $b($getTurn($1)) $+ 's turn.
}
alias getPlayerCards {
  var %cards = $null
  var %i 1
  var %playerSections = $mini($1, $playerSection($2), 0)
  while (%i <= %playerSections) {
    var %iniSec = $mini($1, $playerSection($2), %i)
    if ($startsWith(%iniSec, card.)) {
      var %card = $right(%iniSec, $calc($len(%iniSec) - $len(card.)))
      var %cards $sentencify(%cards, $cardName(%card) $+([x,$getPlayerCardAmount($1,$2,%card),]) $+([,$readCard(%card,roll),]))
    }
    inc %i
  }
  return %cards
}
alias sentencify {
  return $iif($1,$1 $+ $chr(44) $+ $chr(32),$null) $+ $2
}
;; $1 = Channel
alias mreset {
  mremovesectionstartingwith $1 temp_card_
  mremovesectionstartingwith $1 commands
  mremovesectionstartingwith $1 gameSettings
  mremovesectionstartingwith $1 player
  mremove $1 market
}
alias getPlayerCoins {
  var %i 1
  while (%i <= $playerAmount($1)) {
    var %pl = $mini($1, players, %i)
    var %score = $sentencify(%score, $b(%pl) $+ : $coinage($getCoins($1,%pl)))
    inc %i
  }
  return %score
}

alias getHeading {
  if ($1 == cn) return Card Name
  if ($1 == t) return Type
  if ($1 == i) return Income
  if ($1 == a) return Amount
  if ($1 == c) return Cost
  if ($1 == r) return Roll
}
; $1 = Channel, $2- = Constraints
alias initializeCards {
  mremove $1 temp_card_handlers
  mremove $1 temp_card_types
  mremove $1 temp_card_rolls
  mremove $1 temp_card_reverse
  mremove $1 temp_card_hooks

  var %cardName = $getHeading(cn)
  var %cardType = $getHeading(t)
  var %cardReceives = $getHeading(i)
  var %cardAmount = $getHeading(a)
  var %cardCost = $getHeading(c)
  var %cardRoll = $getHeading(r)
  setMaxLength $1 name %cardName
  setMaxLength $1 type %cardType
  setMaxLength $1 cost %cardCost
  setMaxLength $1 roll %cardRoll
  setMaxLength $1 amount %cardAmount
  setMaxLength $1 receive %cardReceives

  var %i = 1
  while (%i <= $ini(machi_cards.ini,0) ) {
    var %section = $ini(machi_cards.ini,%i)
    if (!$cardSectionIgnored(%section)) {
      var %roll = $readCard(%section,roll)
      initializeCard $1 %section $iif(%roll,$v1,0) $readCard(%section, type) $readCard(%section, handler) $iif($readCard(%section, required_for_win),1,0) $readCard(%section, hooks) 
    }
    inc %i
  } 
}

alias setMaxLength {
  var %l = $slen($3-)
  var %cl = $getMaxLength($1, $2)
  if (%cl == $null || %l > %cl) {
    mwrite $1 temp_card_lengths max_ $+ $2 $+ _length %l

  }
}
;; $1 chan $2 property
alias getMaxLength {
  return $mread($1, temp_card_lengths, max_ $+ $2 $+ _length)
}
;$1 = channel $2 = card section $3 = roll numbers $4 = type $5 = Handler $6 = Required for win $7 = hooks 
alias initializeCard {
  var %x = 1
  var %rollNumbers = $numtok($3, 44)
  mwrite $1 temp_card_handlers $5 $addtok($mread($1,temp_card_handlers,$5),$2,44)
  mwrite $1 temp_card_types $4 $addtok($mread($1,temp_card_types,$4),$2,44)
  mwrite $1 temp_card_reverse $md5($lower($readCard($2,name))) $2


  ;; Temporary max lengths for formatting the send output correctly
  setMaxLength $1 name $cardName($2, $true)
  setMaxLength $1 type $formatCardType($2)
  setMaxLength $1 cost $formatCardCost($2, $true)
  setMaxLength $1 roll $formatCardRoll($2)
  setMaxLength $1 amount $formatCardAmount($1, $2)
  setMaxLength $1 receive $formatCardReceive($2, $true)



  addCardToMarket $1 $2 $iif($readCard($2, in_market),$v1,0)


  if ($6 == 1) {
    mSetSetting $1 win_cards $addtok($mGetSetting($1,win_cards),$2,44)
  }

  while (%x <= %rollNumbers) {
    var %rollCounter = $gettok($3,%x,44)
    mwrite $1 temp_card_rolls %rollCounter $addtok($mread($1,temp_card_rolls,%rollCounter),$2,44)
    inc %x
  }
  ; Registering event hooks
  var %hookIndex = 1
  while (%hookIndex <= $numtok($7,44)) {
    var %hookName = $gettok($7,%hookIndex,44)
    mwrite $1 temp_card_hooks %hookName $addtok($mread($1, temp_card_hooks, %hookName), $2, 44)
    inc %hookIndex
  }
}

on *:TEXT:*:#:{
  ;; mwrite $1 commands. $+ $2 $4 $3
  var %handler = $mread($chan,commands. $+ $nick,$1)
  if (%handler != $null) {
    var %isHandled = $execIdentifier(%handler,$chan,$nick,$2-)

    ;machiMessage $chan Command is handled: %isHandled
    if (%isHandled) {
      deRegisterCommand $chan $nick $1
      if ($mGetSetting($chan,waitingFor) == 0) {
        if ($isProcessingPaused($chan)) {
          mResumeProcessing $chan
        }
        else {
          nextTurn $chan
        }
        ;  nextTurn $chan
      }
      else {
        ; machiMessage $chan Debug: Turn is not yet settled. Cannot continue.
      }
    }
    halt
  }
  if ($1 == !machiKoro) {
    if (!$mIsInitializing($chan)) {
      if (!$mIsStarted($chan)) {
        mInitGame $chan $2-
        machiJoin $chan $nick
        machiMessage $chan Starting $b(Machi Koro) $+ . Type $b(!mJoin) to join the game, or $b(!mStart) to begin playing. Only 4 slots remaining.
      }
      else { 
        machiMessage $chan Sorry $b($nick) $+ , the games already started. Wait until next time to play.
      }
    }
    else {
      machiMessage $chan Machi Koro is already starting $b($nick) $+ , type $b(!mJoin) to join the current game.

    }
  }
  else if ($1 == !forceInit && $nick isop $chan) {
    initializeCards $chan
  }
  else if ($1 == !mJoin) {
    if (!$misJoined($chan,$nick) && $mIsInitializing($chan)) {

      machiMessage $chan $b($nick) has just joined the current game.
      machiJoin $chan $nick
    }
    else if ($mIsStarted($chan)) {
      machiMessage $chan Sorry $b($nick) $+ , the games already started. You cannot join an in progress game.
    }
    else {
      machiMessage $chan You have already joined the current game.
    }
  }
  else if ($1 == !forceaddCard && $nick isop $chan) {
  var %user $iif($2 != -p,$nick,$3)
    var %card $iif($2 != -p,$translateCard($chan, $2-),$translateCard($chan,$4-))
    msg $chan card: %card
    if (%card) {
      addPlayerCard $chan %user %card 
      machiMessage $chan Forcing add of card $cardName(%card)

    }
  }
  else if ($1 == !stopMachiKoro && $nick isop $chan) {
    mreset $chan
    machiMessage $chan Game has been ended by $b($nick)
  }
  else if ($1 == !quit) {
    if ($mIsJoined($chan, $nick)) {
      mremoveplayer $chan $nick
      if ($playerAmount($1) <= 0) {
        mreset $chan
        machiMessage $chan Game has ended as there is no longer enough players.
      }
    }
    else {
      machiMessage $chan $b($nick) $+ , you are not part of the current game.
    }
  }
  else if ($1 == !kick && $nick isop $chan) {
    if ($mIsJoined($chan, $2)) {
      mremoveplayer $chan $2
      if ($playerAmount($1) <= 0) {
        mreset $chan
        machiMessage $chan Game has ended as there is no longer enough players.
      }
    }
    else {
      machiMessage $chan $b($2) is not part of the current game.
    }
  }
  else if ($1 == !coins) {
    machiNotice $nick Current coin amounts: $getPlayerCoins($chan)
  }
  else if ($1 == !enableExtension && $nick isop $chan) {
    machiMessage $chan Extension enabled.
    enableExtension $1 $2-
  }
  else if ($1 == !disableExtension && $nick isop $chan) {
    machiMessage $chan Extension disabled
    disableExtension $1 $2-
  }
  else if ($1 == !cards) {
    var %nick $iif($2,$2,$nick)
    if ($mIsJoined($chan, $nick)) {
      machiNotice $nick $getPlayerCards($chan, %nick)
    }
    else {
      machiMessage $chan $b($nick) there is no such player that has joined the game.
    }
  }
  else if ($1 == !mstop && $nick isop $chan) {
    machiMessage $chan Stopped game
    mreset $chan
  }
  else if ($1 == !mStart) {  
    if ($mIsInitializing($chan)) {
      mStartGame $chan
    }
    else {
      machiMessage $chan $b($nick) there is no game to be started. Either start a game with $b(!machikoro) or play the game thats currently going on.
    }
  }
  else if ($1 == !forceJoin && $nick isop $chan) {
    machiMessage $chan $iif($2,$2,$nick) has been added to the game.
    machiJoin $chan $iif($2,$2,$nick)
  }
  else if ($1 == !forceNextTurn && $nick isop $chan) {
    machiMessage $chan Resetting waiting for and moving on...
    msetsetting $chan waitingFor 0
    nextTurn $chan 
  }
  else if ($1 == !forceRoll && $nick isop $chan) {
    processRoll $chan $2 $iif($3,$3,$nick)
  }
  if ($1 == !roll && $getTurn($chan) == $nick) {
    if (!$getPlayerSetting($chan, $nick, hasRolled)) {
      var %eventID $createEvent($chan, onBeforeDiceRoll)
      noop $setEventValues($chan, %eventID, $false, nick $nick, message $1-)
      var %continue $dispatchEvent($chan, %eventID, $false)
      if ($eventInfo($chan, %eventID).isHandled) {

        setPlayerSetting $chan $nick hasRolled $true
      }
      ; msg $chan Got roll %continue $mGetSetting($chan,waitingFor)
      if (%continue) {

        setPlayerSetting $chan $nick hasRolled $true
        var %roll = $rand(1,6)
        mRoll $chan $nick 1
      }

    }
    else {
      machiMessage $chan $b($nick) you have already rolled. Complete the rest of your turn before rolling again. 
    }
  }
}
