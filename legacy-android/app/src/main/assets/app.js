(function () {
  "use strict";
  var CONTENT = document.getElementById("content");
  var MODAL = document.getElementById("modal-root");
  var NOTICE = document.getElementById("app-notice");
  var HEADER = document.getElementById("app-header");
  var HEADER_BACK = document.getElementById("header-back");
  var HEADER_SUBTITLE = document.getElementById("header-subtitle");
  var state, view = { page: "home" }, navStack = [], modalState = null;
  var editDeckId = null, editCardDeckId = null, editCardId = null, imageTarget = "front";
  var session = null, studyInterval = null, focusInterval = null, focusRunning = false, autoRevealHandle = null;
  var focusDuration = 30, focusRemaining = 30 * 60, focusStartedAt = 0, musicPlaying = false, zoomScale = 1;
  var pendingImport = null, downloadedBackupName = null, searchTerm = "", smartMixSize = 20, smartMixFilter = "all";
  var pendingStudyRefs = null, pendingStudyLabel = "";
  var languages = [
    ["fa","فارسی"],["en","English"],["de","Deutsch"],["de-CH","Deutsch (Schweiz)"],["de-AT","Deutsch (Österreich)"],
    ["nl","Nederlands"],["es","Español"],["pt","Português"],["fr","Français"],["da","Dansk"],["no","Norsk"],
    ["fi","Suomi"],["sv","Svenska"],["is","Íslenska"],["el","Ελληνικά"],["ar","العربية"],["he","עברית"],
    ["ja","日本語"],["ko","한국어"],["it","Italiano"],["tr","Türkçe"]
  ];

  function defaults() {
    return {
      decks: [],
      settings: {
        themeIndex: 0, appearanceMode: "aero", languageCode: "fa", animations: true, haptics: true,
        autoReveal: false, autoRevealDelaySeconds: 3, showProgress: true, showTimer: true, glass: true, showXp: true,
        confirmExit: true, compactSettings: false, glassOpacity: 0.62, dailyGoal: 20,
        musicEnabled: false, musicTrack: "lofi_night", musicVolume: 0.35
      },
      xp: 0, streak: 0, lastStudyDay: null, lastRewardDay: null, reviewDays: [],
      dailyGoodRatings: 0, dailyGoodRatingsDay: null, dailyCardsCreated: 0, dailyCardsCreatedDay: null
    };
  }

  function uid() { return String(new Date().getTime()) + String(Math.floor(Math.random() * 1000000)); }
  function clone(obj) { return JSON.parse(JSON.stringify(obj)); }
  function parseJson(s, fallback) { try { return JSON.parse(s); } catch (e) { return fallback; } }
  function text(value) { return value === null || value === undefined ? "" : String(value); }
  function esc(value) { return text(value).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#39;"); }
  function attr(value) { return esc(value); }
  function pad(n) { return n < 10 ? "0" + n : String(n); }
  function dateKey(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()); }
  function dateFrom(value) { var n = Date.parse(value); return isNaN(n) ? new Date() : new Date(n); }
  function isDue(card) { return dateFrom(card.due).getTime() <= new Date().getTime(); }
  function fmtDate(value) {
    var d = dateFrom(value);
    try { return d.toLocaleDateString(state.settings.languageCode.split("-")[0], {year:"numeric", month:"short", day:"numeric"}); }
    catch (e) { return d.getFullYear() + "-" + pad(d.getMonth()+1) + "-" + pad(d.getDate()); }
  }
  function duration(seconds) { seconds = Math.max(0, Math.floor(seconds)); return pad(Math.floor(seconds / 60)) + ":" + pad(seconds % 60); }
  function translate(key) {
    var code = state && state.settings ? state.settings.languageCode : "fa";
    var dict = window.PARIN_TRANSLATIONS[code] || window.PARIN_TRANSLATIONS[code.split("-")[0]] || window.PARIN_TRANSLATIONS.en || {};
    return dict[key] || (window.PARIN_TRANSLATIONS.en || {})[key] || key;
  }
  function theme() {
    var i = state.settings.themeIndex || 0;
    return window.PARIN_THEMES[Math.max(0, Math.min(window.PARIN_THEMES.length - 1, i))] || window.PARIN_THEMES[0];
  }
  function primaryColor() {
    var t = theme();
    return state.settings.appearanceMode === "dark" || state.settings.appearanceMode === "amoled" ? t.secondary : t.primary;
  }
  function primaryStyle() { return ' style="background:' + primaryColor() + ';border-color:' + primaryColor() + ';"'; }
  function btn(label, action, extra, kind) {
    var k = kind || "button";
    return '<button type="button" class="button ' + esc(k) + '" data-action="' + esc(action) + '"' + (extra || "") + (k.indexOf("primary") >= 0 ? primaryStyle() : "") + '>' + label + '</button>';
  }
  function smallBtn(label, action, extra, kind) { return btn(label, action, extra, (kind || "") + " small"); }
  function pageHead(title, subtitle) {
    return '<h1 class="page-title">' + esc(title) + '</h1>' + (subtitle ? '<p class="page-subtitle">' + esc(subtitle) + '</p>' : "");
  }
  function panel(title, body, extra) {
    return '<section class="panel"' + (extra || "") + '>' + (title ? '<div class="panel-header"><h2 class="panel-title">' + esc(title) + '</h2></div>' : "") + body + '</section>';
  }
  function metric(value, label) {
    return '<div class="metric"><div class="metric-value">' + esc(value) + '</div><div class="metric-label">' + esc(label) + '</div></div>';
  }
  function progressBar(value, color) {
    var percent = Math.max(0, Math.min(100, value * 100));
    return '<div class="progress"><div class="progress-fill" style="width:' + percent + '%;background:' + (color || primaryColor()) + ';"></div></div>';
  }
  function badge(label, color) {
    return '<span class="badge"' + (color ? ' style="background:' + color + ';color:#fff"' : "") + '>' + esc(label) + '</span>';
  }
  function getDeck(id) {
    for (var i=0;i<state.decks.length;i++) if (state.decks[i].id === id) return state.decks[i];
    return null;
  }
  function getCard(deckId, id) {
    var d=getDeck(deckId); if(!d)return null;
    for(var i=0;i<d.cards.length;i++) if(d.cards[i].id===id)return d.cards[i];
    return null;
  }
  function defaultBoxes() {
    return [
      {id:"b1",name:"خانه ۱",color:4286352639},{id:"b2",name:"خانه ۲",color:4283204863},
      {id:"b3",name:"خانه ۳",color:4280721066},{id:"b4",name:"خانه ۴",color:4294948646},
      {id:"b5",name:"خانه ۵",color:4293881264}
    ];
  }
  function normalizeDeck(deck) {
    if (!deck || typeof deck !== "object") return null;
    deck.id = text(deck.id || uid());
    deck.name = text(deck.name || "Untitled deck");
    deck.description = text(deck.description || "");
    deck.color = text(deck.color || "6C63FF");
    if (Object.prototype.toString.call(deck.cards) !== "[object Array]") deck.cards = [];
    if (Object.prototype.toString.call(deck.boxes) !== "[object Array]") deck.boxes = defaultBoxes();
    deck.cards = deck.cards.filter(function (c) { return c && typeof c === "object"; }).map(normalizeCard);
    deck.boxes = (deck.boxes || []).filter(function (b) { return b && typeof b === "object"; });
    if (!deck.boxes.length) deck.boxes = defaultBoxes();
    return deck;
  }
  function normalizeCard(card) {
    card.id = text(card.id || uid()); card.front = text(card.front); card.back = text(card.back);
    card.tags = text(card.tags || ""); card.box = parseInt(card.box,10); if(isNaN(card.box)||card.box<0)card.box=0;
    card.due = text(card.due || new Date().toISOString()); card.favorite = !!card.favorite;
    card.reviews = Math.max(0,parseInt(card.reviews,10)||0); card.lapses = Math.max(0,parseInt(card.lapses,10)||0);
    card.difficulty = ["auto","hard","medium","easy"].indexOf(card.difficulty)>=0 ? card.difficulty : "auto";
    card.frontImage = card.frontImage || null; card.backImage = card.backImage || null;
    return card;
  }
  function loadState() {
    var raw = "";
    try { raw = Native.loadData(); } catch (e) { raw = ""; }
    var loaded = raw ? parseJson(raw, null) : null;
    state = defaults();
    if (Object.prototype.toString.call(loaded) === "[object Array]") state.decks = loaded;
    else if (loaded && typeof loaded === "object") {
      state.decks = Object.prototype.toString.call(loaded.decks) === "[object Array]" ? loaded.decks : [];
      if (loaded.settings) {
        for (var k in state.settings) if (Object.prototype.hasOwnProperty.call(loaded.settings,k)) state.settings[k] = loaded.settings[k];
      }
      state.xp = Math.max(0,parseInt(loaded.xp,10)||0);
      state.streak = Math.max(0,parseInt(loaded.streak,10)||0);
      state.lastStudyDay = loaded.lastStudyDay || null; state.lastRewardDay = loaded.lastRewardDay || null;
      state.reviewDays = Object.prototype.toString.call(loaded.reviewDays)==="[object Array]" ? loaded.reviewDays : [];
      state.dailyGoodRatings = Math.max(0,parseInt(loaded.dailyGoodRatings,10)||0);
      state.dailyGoodRatingsDay = loaded.dailyGoodRatingsDay || null;
      state.dailyCardsCreated = Math.max(0,parseInt(loaded.dailyCardsCreated,10)||0);
      state.dailyCardsCreatedDay = loaded.dailyCardsCreatedDay || null;
    }
    state.decks = state.decks.map(normalizeDeck).filter(function(d){return !!d;});
    state.settings.themeIndex = Math.max(0, Math.min(49, parseInt(state.settings.themeIndex,10)||0));
    if (["light","dark","aero","amoled"].indexOf(state.settings.appearanceMode)<0)state.settings.appearanceMode="aero";
    if (!window.PARIN_TRANSLATIONS[state.settings.languageCode])state.settings.languageCode="fa";
    if (["lofi_night","rainy_focus","deep_focus"].indexOf(state.settings.musicTrack)<0)state.settings.musicTrack="lofi_night";
    state.settings.glassOpacity = Math.max(.30,Math.min(.90,parseFloat(state.settings.glassOpacity)||.62));
    state.settings.dailyGoal = Math.max(5,Math.min(100,parseInt(state.settings.dailyGoal,10)||20));
    state.settings.autoRevealDelaySeconds = Math.max(1,Math.min(30,parseInt(state.settings.autoRevealDelaySeconds,10)||3));
    state.settings.musicVolume = Math.max(0,Math.min(1,parseFloat(state.settings.musicVolume)||0));
    if (!state.decks.length) {
      state.decks.push(normalizeDeck({id:"demo",name:"شروع سریع",description:"کارت‌های نمونه",color:"3F51B5",cards:[
        {id:uid(),front:"Leitner چیست؟",back:"یک روش مرور فاصله‌دار برای انتقال کارت‌ها بین خانه‌ها.",box:0,due:new Date().toISOString()},
        {id:uid(),front:"Flutter چیست؟",back:"فریم‌ورک ساخت رابط کاربری چندسکویی با Dart.",box:0,due:new Date().toISOString()}
      ],boxes:defaultBoxes()}));
    }
  }
  function persist() {
    try { Native.saveData(JSON.stringify(state)); } catch (e) { notify("Could not save data on this device."); }
  }
  function applyAppearance() {
    var mode = state.settings.appearanceMode;
    var rtl = ["fa","ar","he"].indexOf(state.settings.languageCode.split("-")[0]) >= 0;
    document.body.className = "mode-" + mode + (rtl ? " rtl" : "") +
      (state.settings.animations ? "" : " no-animations") +
      (state.settings.compactSettings ? " compact-settings" : "");
    var t=theme(), dark=mode==="dark"||mode==="amoled", aero=mode==="aero";
    document.body.style.backgroundColor = dark ? (mode==="amoled" ? "#000000" : "#101114") : (aero ? "#eaf0fa" : t.background);
    HEADER.style.backgroundColor = dark ? (mode==="amoled" ? "#000000" : "#181a1f") : (aero ? t.secondary : t.primary);
    HEADER.style.color = dark ? "#f5f7fa" : (aero ? "#202124" : "#ffffff");
    var isrtl = rtl;
    document.getElementById("bottom-nav").style.direction = isrtl ? "rtl" : "ltr";
    HEADER_BACK.style.display = view.page==="home" ? "none" : "block";
    HEADER_SUBTITLE.textContent = view.page==="home" ? translate("ready") : translate(view.page==="deck" ? "decks" : view.page==="settings" ? "settings" : view.page==="study" ? "study" : view.page==="focus" ? "focus_mode" : view.page==="stats" ? "experience" : view.page==="about" ? "about" : "extra");
    if (view.page === "home") HEADER_SUBTITLE.textContent = "Android 4.0+ • " + translate("ready");
    var navButtons=document.querySelectorAll("#bottom-nav button");
    var navLabels=[translate("home"),translate("study"),translate("focus_mode"),translate("experience")];
    for(var i=0;i<navButtons.length;i++){
      var p=navButtons[i].getAttribute("data-page");
      var act=navButtons[i].getAttribute("data-action");
      navButtons[i].className = ((p && p===view.page) || (act==="study-all"&&view.page==="study")) ? "active" : "";
      if(navButtons[i].className==="active")navButtons[i].style.color=primaryColor();else navButtons[i].style.color="";
      var small=navButtons[i].querySelector("small");if(small)small.textContent=navLabels[i]||"";
    }
  }
  function applySurfaceAppearance() {
    var mode = state.settings.appearanceMode;
    var surfaces = CONTENT.querySelectorAll(".panel, .study-card");
    for (var i = 0; i < surfaces.length; i++) {
      if (mode === "aero") {
        var opacity = state.settings.glass ? state.settings.glassOpacity : 0.97;
        surfaces[i].style.backgroundColor = "rgba(255,255,255," + opacity + ")";
      } else {
        surfaces[i].style.backgroundColor = "";
      }
    }
  }
  function notify(message) {
    var n=document.createElement("div");n.className="notice";n.appendChild(document.createTextNode(text(message)));
    NOTICE.appendChild(n);
    window.setTimeout(function(){if(n.parentNode)n.parentNode.removeChild(n);},2600);
  }
  function setCanGoBack() { try { Native.setCanGoBack(navStack.length>0 || view.page!=="home"); } catch(e){} }
  function goto(page, params) {
    if(view.page==="study" && page!=="study") stopStudyTimer();
    if(view.page==="focus" && page!=="focus") pauseFocusForNavigation();
    navStack.push(clone(view)); view={page:page,params:params||{}};
    render(); setCanGoBack();
  }
  function replaceView(page, params) {
    if(navStack.length) navStack.pop();
    view={page:page,params:params||{}};
    render();setCanGoBack();
  }
  function back() {
    if(view.page==="study" && session && !session.finished && state.settings.confirmExit) {
      showModal(translate("confirm_exit"),'<p>'+esc(translate("confirm_exit_sub"))+'</p>',[
        {label:translate("cancel"),action:"close-modal"},
        {label:translate("close"),action:"confirm-study-exit",primary:true}
      ]);
      return;
    }
    if(view.page==="study") stopStudyTimer();
    if(view.page==="focus") pauseFocusForNavigation();
    if(navStack.length) view=navStack.pop(); else view={page:"home"};
    render();setCanGoBack();
  }
  window.handleNativeBack=function(){ if(modalState){closeModal();return;} back(); };
  function showModal(title, body, actions) {
    modalState=true;
    var buttons="";
    for(var i=0;i<(actions||[]).length;i++) {
      var a=actions[i];
      buttons+=btn(esc(a.label),a.action,a.extra||"",a.primary?"button primary":"button");
    }
    MODAL.innerHTML='<div class="modal-backdrop" data-action="backdrop-close"><div class="modal" role="dialog" aria-modal="true"><h2 class="modal-title">'+esc(title)+'</h2><div class="modal-body">'+(body||"")+'</div><div class="modal-actions">'+buttons+'</div></div></div>';
    var backdrop=MODAL.firstChild;
    backdrop.onclick=function(e){if(e.target===backdrop)closeModal();};
  }
  function closeModal(){modalState=false;MODAL.innerHTML="";}
  function stats() {
    var cards=[],due=0,fav=0,reviews=0,boxes=0;
    for(var i=0;i<state.decks.length;i++){
      var d=state.decks[i];boxes+=d.boxes.length;
      for(var j=0;j<d.cards.length;j++){
        var c=d.cards[j];cards.push({deck:d,card:c});if(isDue(c))due++;if(c.favorite)fav++;reviews+=c.reviews||0;
      }
    }
    return {cards:cards,total:cards.length,due:due,favorites:fav,reviews:reviews,boxes:boxes};
  }
  function render() {
    applyAppearance();
    var html="";
    switch(view.page){
      case "home": html=renderHome();break;
      case "deck": html=renderDeck(view.params.deckId);break;
      case "deckEdit": html=renderDeckEditor();break;
      case "cardEdit": html=renderCardEditor();break;
      case "boxes": html=renderBoxes();break;
      case "study": html=renderStudy();break;
      case "focus": html=renderFocus();break;
      case "settings": html=renderSettings();break;
      case "stats": html=renderStats();break;
      case "achievements": html=renderAchievements();break;
      case "power": html=renderPowerCenter();break;
      case "about": html=renderAbout();break;
      default: html=renderHome();view={page:"home"};
    }
    CONTENT.innerHTML=html;
    applySurfaceAppearance();
    bindSearch();
    setCanGoBack();
  }
  function renderHome() {
    var s=stats(),goal=state.settings.dailyGoal,ratio=goal?Math.min(1,s.due/goal):0;
    var out=pageHead("Parin Litner",translate("ready"));
    out+='<div class="grid">'+metric(s.total,translate("cards"))+metric(s.due,translate("cards_ready"))+metric(s.favorites,translate("favorite_only"))+metric(state.xp,"XP • Level "+(1+Math.floor(state.xp/250)))+'</div>';
    out+=panel(translate("today"),'<div class="row between"><strong>'+esc(s.due)+' / '+esc(goal)+'</strong><span class="muted">'+esc(translate("daily_goal"))+'</span></div><div style="margin-top:8px">'+progressBar(ratio)+'</div><p class="muted">'+esc(translate("streak")||"Streak")+': '+state.streak+' • '+esc(translate("week_reviews")||"This week")+': '+weekReviews()+'</p>'+
      '<div class="row wrap">'+btn(esc(translate("study")),"study-all","", "button primary")+' '+btn(esc(translate("focus_mode")),"goto",' data-page="focus"')+' '+btn(esc(translate("achievement_center")),"goto",' data-page="achievements"')+'</div>');
    out+='<div class="row between"><h2 class="section-title">'+esc(translate("decks"))+'</h2>'+btn("+ "+esc(translate("new_deck")),"new-deck","","button primary")+'</div>';
    if(!state.decks.length) out+=panel("",'<div class="empty-state">'+esc(translate("no_cards"))+'</div>');
    for(var i=0;i<state.decks.length;i++){
      var d=state.decks[i],dDue=0;
      for(var j=0;j<d.cards.length;j++)if(isDue(d.cards[j]))dDue++;
      var col=paletteForDeck(d);
      out+='<section class="panel deck-card" style="border-left-color:'+col+'"><div class="row between"><div class="grow" data-action="open-deck" data-id="'+attr(d.id)+'"><div class="deck-title">'+esc(d.name)+'</div><div class="deck-description">'+esc(d.description)+'</div></div><span class="badge">'+dDue+' '+esc(translate("ready_count"))+'</span></div><div class="row wrap" style="margin-top:10px">'+
        smallBtn(esc(translate("study")),"study-deck",' data-id="'+attr(d.id)+'"',"button primary")+' '+smallBtn(esc(translate("new_card")),"new-card",' data-deck="'+attr(d.id)+'"')+' '+smallBtn(esc(translate("rename")),"edit-deck",' data-id="'+attr(d.id)+'"')+'</div></section>';
    }
    out+=panel(translate("backup"),'<div class="row wrap">'+btn(esc(translate("export")),"export-backup","","button primary")+' '+btn(esc(translate("import")),"import-backup")+'</div>');
    return out;
  }
  function paletteForDeck(deck) {
    for(var i=0;i<window.PARIN_THEMES.length;i++) if(window.PARIN_THEMES[i].primary.replace("#","").toLowerCase()===text(deck.color).replace("#","").toLowerCase())return window.PARIN_THEMES[i].primary;
    return primaryColor();
  }
  function renderDeck(deckId) {
    var d=getDeck(deckId);if(!d)return pageHead(translate("decks"),"")+panel("",'<div class="empty-state">'+esc(translate("no_cards"))+'</div>');
    var due=0,fav=0;for(var i=0;i<d.cards.length;i++){if(isDue(d.cards[i]))due++;if(d.cards[i].favorite)fav++;}
    var out=pageHead(d.name,d.description);
    out+='<div class="grid">'+metric(d.cards.length,translate("cards"))+metric(due,translate("cards_ready"))+metric(fav,translate("favorite_only"))+'</div>';
    out+=panel("",'<div class="row wrap">'+btn(esc(translate("study")),"study-deck",' data-id="'+attr(d.id)+'"',"button primary")+' '+btn(esc(translate("new_card")),"new-card",' data-deck="'+attr(d.id)+'"')+' '+btn(esc(translate("boxes")),"manage-boxes",' data-id="'+attr(d.id)+'"')+'</div>'+
      '<div class="row wrap" style="margin-top:8px">'+btn(esc(translate("rename")),"edit-deck",' data-id="'+attr(d.id)+'"')+' '+btn(esc(translate("delete")),"delete-deck",' data-id="'+attr(d.id)+'"',"button danger")+'</div>');
    out+='<label class="field">'+esc(translate("search"))+'</label><input type="search" class="search-box" placeholder="'+attr(translate("search"))+'" value="'+attr(searchTerm)+'" data-search="cards">';
    if(!d.cards.length) out+=panel("",'<div class="empty-state">'+esc(translate("no_cards"))+'</div>');
    else {
      out+='<section class="panel" id="card-list">';
      for(var j=0;j<d.cards.length;j++){
        var c=d.cards[j],box=d.boxes[Math.min(c.box,d.boxes.length-1)]||d.boxes[0],filter=(c.front+" "+c.back+" "+c.tags).toLowerCase();
        out+='<div class="card-row" data-filter="'+attr(filter)+'"><div class="row between"><div class="grow"><div class="card-text">'+esc(c.front || translate("image_unavailable"))+'</div><div class="card-back-preview">'+esc(c.back)+'</div><div style="margin-top:4px">'+badge(box?box.name:"Box "+(c.box+1),box?colorFromValue(box.color):primaryColor())+(c.favorite?badge("★ "+translate("favorite_only")):"")+(c.tags?badge(c.tags):"")+'</div><div class="muted" style="margin-top:4px">'+esc(isDue(c)?translate("cards_ready"):translate("next_review")+": "+fmtDate(c.due))+' • '+esc(translate("reviews")||"Reviews")+': '+c.reviews+'</div></div>';
        if(c.frontImage)out+='<img src="'+attr(imageUrl(c.frontImage))+'" alt="" style="width:56px;height:56px;object-fit:cover;border-radius:4px;margin:0 5px;">';
        out+='</div><div class="row wrap" style="margin-top:7px">'+smallBtn(esc(translate("edit_card")),"edit-card",' data-deck="'+attr(d.id)+'" data-id="'+attr(c.id)+'"')+' '+smallBtn(c.favorite?"★":"☆","favorite-card",' data-deck="'+attr(d.id)+'" data-id="'+attr(c.id)+'"')+' '+smallBtn(esc(translate("delete")),"delete-card",' data-deck="'+attr(d.id)+'" data-id="'+attr(c.id)+'"',"button danger")+'</div></div>';
      }
      out+='</section>';
    }
    return out;
  }
  function renderDeckEditor() {
    var d=editDeckId?getDeck(editDeckId):null, editing=!!d;
    var out=pageHead(translate("new_deck")+(editing?" • "+translate("rename"):""),translate("new_deck_hint"));
    out+='<form data-form="deck" class="panel"><label class="field" for="deck-name">'+esc(translate("new_deck_hint"))+'</label><input id="deck-name" type="text" maxlength="100" required value="'+attr(d?d.name:"")+'">';
    out+='<label class="field" for="deck-description">'+esc(translate("description")||"Description")+'</label><textarea id="deck-description" maxlength="500">'+esc(d?d.description:"")+'</textarea>';
    out+='<label class="field" for="deck-color">'+esc(translate("theme"))+'</label><select id="deck-color">';
    for(var i=0;i<window.PARIN_THEMES.length;i++){
      var t=window.PARIN_THEMES[i],sel=d&&d.color.toLowerCase()===t.primary.slice(1).toLowerCase()?" selected":"";
      out+='<option value="'+t.primary.slice(1)+'"'+sel+'>'+esc(t.name)+'</option>';
    }
    out+='</select><div class="form-actions"><button class="button primary" type="submit"'+primaryStyle()+'>'+esc(translate("save"))+'</button>'+btn(esc(translate("cancel")),"back")+'</div></form>';
    return out;
  }
  function renderCardEditor() {
    var d=getDeck(editCardDeckId),c=editCardId?getCard(editCardDeckId,editCardId):null;
    if(!d)return pageHead(translate("edit_card"),"");
    var out=pageHead(c?translate("edit_card"):translate("new_card"),d.name);
    out+='<form data-form="card" class="panel"><label class="field" for="front">'+esc(translate("card_front"))+'</label><textarea id="front" maxlength="20000">'+esc(c?c.front:"")+'</textarea>';
    out+=imageInput("front",d._editingFrontImage!==undefined?d._editingFrontImage:(c?c.frontImage:null));
    out+='<label class="field" for="back">'+esc(translate("card_back"))+'</label><textarea id="back" maxlength="20000">'+esc(c?c.back:"")+'</textarea>';
    out+=imageInput("back",d._editingBackImage!==undefined?d._editingBackImage:(c?c.backImage:null));
    out+='<label class="field" for="card-tags">'+esc(translate("tags"))+'</label><input type="text" id="card-tags" maxlength="500" value="'+attr(c?c.tags:"")+'" placeholder="'+attr(translate("tags_hint"))+'">';
    out+='<label class="field" for="card-box">'+esc(translate("box"))+'</label><select id="card-box">';
    for(var i=0;i<d.boxes.length;i++)out+='<option value="'+i+'"'+(c&&c.box===i?" selected":"")+'>'+esc(d.boxes[i].name)+'</option>';
    out+='</select><label class="field" for="card-difficulty">'+esc(translate("card_difficulty"))+'</label><select id="card-difficulty">'+
      '<option value="auto"'+(!c||!c.difficulty||c.difficulty==="auto"?" selected":"")+'>'+esc(translate("difficulty_auto"))+'</option>'+
      '<option value="easy"'+(c&&c.difficulty==="easy"?" selected":"")+'>'+esc(translate("easy"))+'</option>'+
      '<option value="medium"'+(c&&c.difficulty==="medium"?" selected":"")+'>'+esc(translate("difficulty_medium"))+'</option>'+
      '<option value="hard"'+(c&&c.difficulty==="hard"?" selected":"")+'>'+esc(translate("hard"))+'</option></select>'+
      '<label class="setting-row"><input id="card-favorite" type="checkbox"'+(c&&c.favorite?" checked":"")+'><span class="setting-copy"><span class="setting-name">'+esc(translate("favorite_only"))+'</span></span></label>';
    out+='<div class="form-actions"><button class="button primary" type="submit"'+primaryStyle()+'>'+esc(translate("save_card"))+'</button>'+btn(esc(translate("cancel")),"back")+'</div></form>';
    return out;
  }
  function imageInput(side, value) {
    var title=translate(side==="front"?"front_image":"back_image"),html='<div class="image-frame"><div class="muted">'+esc(title)+'</div>';
    if(value)html+='<img src="'+attr(imageUrl(value))+'" alt="'+attr(title)+'">';
    else html+='<p class="muted">'+esc(translate("image_unavailable"))+'</p>';
    html+='<div class="row wrap" style="margin-top:6px">'+btn(esc(value?translate("change_image"):translate("add_image")),"pick-image",' data-side="'+side+'"')+(value?smallBtn(esc(translate("delete")),"clear-image",' data-side="'+side+'"',"button danger"):"")+'</div></div>';
    return html;
  }
  function renderBoxes() {
    var d=getDeck(view.params.deckId);if(!d)return pageHead(translate("boxes"),"");
    var out=pageHead(translate("boxes"),d.name)+'<form data-form="boxes" class="panel">';
    for(var i=0;i<d.boxes.length;i++){
      out+='<div class="setting-row"><div class="setting-copy"><input id="boxname-'+i+'" type="text" maxlength="80" value="'+attr(d.boxes[i].name)+'"></div><span class="badge">'+i+'</span>';
      if(d.boxes.length>1)out+=smallBtn("×","delete-box",' data-index="'+i+'"',"button danger");
      out+='</div>';
    }
    out+='<div class="form-actions"><button class="button primary" type="submit"'+primaryStyle()+'>'+esc(translate("save"))+'</button>'+btn(esc(translate("cancel")),"back")+'</div></form>';
    out+=panel(translate("add_box"),'<form data-form="boxadd"><label class="field" for="new-box-name">'+esc(translate("box_name"))+'</label><input id="new-box-name" type="text" maxlength="80" required><div style="margin-top:9px">'+btn(esc(translate("create")),"add-box","","button primary")+'</div></form>');
    return out;
  }
  function zoomStudyImage() {
    if(!session||session.finished||!session.cards.length)return;
    var ref=session.cards[session.index],card=getCard(ref.deckId,ref.cardId);
    if(!card)return;
    var data=session.revealed?card.backImage:card.frontImage;
    if(!data)return;
    zoomScale=1;
    showModal(translate("zoom_image"),'<div class="legacy-image-zoom"><img id="zoom-study-image" src="'+attr(imageUrl(data))+'" alt="" style="transform:scale(1);transform-origin:center center;max-width:100%;max-height:60vh;object-fit:contain;"></div><div class="row wrap" style="margin-top:10px">'+btn("−","zoom-study-out")+' '+btn("+","zoom-study-in")+'</div>',[{label:translate("close"),action:"close-modal"}]);
  }
  function applyStudyZoom() {
    var img=document.getElementById("zoom-study-image");
    if(img)img.style.transform="scale("+zoomScale+")";
  }

  function renderStudy() {
    if(!session || !session.cards.length) return pageHead(translate("study"),"")+panel("",'<div class="empty-state">'+esc(translate("no_due"))+'</div>'+btn(esc(translate("back")||translate("home")),"back"));
    if(session.finished) return pageHead(translate("done"),"")+panel("",'<div class="empty-state">'+esc(translate("done"))+'</div>'+btn(esc(translate("great")),"finish-study"));
    var ref=session.cards[session.index],c=getCard(ref.deckId,ref.cardId),d=getDeck(ref.deckId);
    if(!c||!d)return pageHead(translate("study"),"");
    var label=session.revealed?translate("answer"):translate("tap");
    var side=session.revealed?"back":"front",img=session.revealed?c.backImage:c.frontImage,content=session.revealed?c.back:c.front;
    var out=pageHead(translate("study"),d.name+' • '+(session.index+1)+' / '+session.cards.length);
    if(state.settings.showTimer)out+='<div class="row between muted" style="margin-bottom:6px"><span>'+esc(translate("timer"))+'</span><strong id="study-clock">'+duration(session.seconds)+'</strong></div>';
    if(state.settings.showProgress)out+=progressBar((session.index+(session.revealed?.9:.1))/session.cards.length);
    out+='<div class="study-card" style="margin-top:13px" data-action="reveal"><div class="muted" style="margin-bottom:12px">'+esc(label)+'</div>';
    if(img)out+='<button type="button" class="study-image-zoom" data-action="zoom-study-image" aria-label="'+attr(translate("zoom_image"))+'"><img class="study-image" src="'+attr(imageUrl(img))+'" alt=""></button>';
    if(content)out+='<div class="study-card-text">'+esc(content)+'</div>';
    if(!content&&!img)out+='<div class="study-card-text">'+esc(translate("image_unavailable"))+'</div>';
    out+='<div class="muted" style="margin-top:16px">'+esc(translate("tap"))+'</div></div>';
    if(session.revealed){
      out+='<div class="rate-grid">'+
        btn(esc(translate("knew_it")),"rate",' data-rating="2"',"button metro-known")+
        btn(esc(translate("did_not_know")),"rate",' data-rating="0"',"button metro-unknown")+'</div>';
      out+='<p class="muted" style="text-align:center">'+esc(translate("swipe"))+'</p>';
    } else out+='<div style="margin-top:12px;text-align:center">'+btn(esc(translate("answer")),"reveal","","button primary")+'</div>';
    if(state.settings.musicEnabled)out+='<div class="row wrap" style="margin-top:10px">'+btn(esc(translate("music_btn")),"toggle-music")+'</div>';
    return out;
  }
  function renderFocus() {
    var out=pageHead(translate("focus_title"),translate("focus_sub"));
    out+=panel(translate("select_duration"),'<div class="row wrap">'+
      btn("15 "+translate("focus_minutes"),"focus-duration",' data-minutes="15"',focusDuration===15?"button primary":"button")+' '+
      btn("30 "+translate("focus_minutes"),"focus-duration",' data-minutes="30"',focusDuration===30?"button primary":"button")+' '+
      btn("45 "+translate("focus_minutes"),"focus-duration",' data-minutes="45"',focusDuration===45?"button primary":"button")+' '+
      btn(esc(translate("custom_minutes")),"focus-custom","","button")+'</div>');
    out+=panel("",'<div id="focus-clock" style="font-size:48px;font-weight:300;text-align:center;padding:16px 0">'+duration(focusRemaining)+'</div><div class="row">'+btn(esc(focusRunning?translate("pause"):translate("start_focus")),"focus-toggle","","button primary")+' '+btn(esc(translate("reset")),"focus-reset")+'</div><label class="setting-row"><input type="checkbox" data-setting="musicEnabled"'+(state.settings.musicEnabled?" checked":"")+'><span class="setting-copy"><span class="setting-name">'+esc(translate("focus_music"))+'</span></span></label>'+
      '<label class="field">'+esc(translate("music"))+'</label><select data-setting="musicTrack"><option value="lofi_night"'+(state.settings.musicTrack==="lofi_night"?" selected":"")+' >Lo-fi Night</option><option value="rainy_focus"'+(state.settings.musicTrack==="rainy_focus"?" selected":"")+' >Rainy Focus</option><option value="deep_focus"'+(state.settings.musicTrack==="deep_focus"?" selected":"")+' >Deep Focus</option></select>');
    return out;
  }

  function settingRow(key, subkey, checked) {
    return '<label class="setting-row"><span class="setting-copy"><span class="setting-name">'+esc(translate(key))+'</span><span class="setting-sub">'+esc(subkey?translate(subkey):"")+'</span></span><input type="checkbox" data-setting="'+attr(key)+'"'+(checked?" checked":"")+'></label>';
  }
  function renderSettings() {
    var s=state.settings,out=pageHead(translate("settings"),"Parin Litner • "+translate("appearance"));
    out+=panel(translate("language"),'<label class="field" for="language-code">'+esc(translate("ui_language"))+'</label><select id="language-code" data-setting="languageCode">'+languageOptions(s.languageCode)+'</select>');
    var modeOptions=[["light","Light"],["dark","Dark"],["aero","Aero Glass"],["amoled","AMOLED Dark"]];
    var mo='<label class="field">'+esc(translate("appearance"))+'</label><select data-setting="appearanceMode">';
    for(var i=0;i<modeOptions.length;i++)mo+='<option value="'+modeOptions[i][0]+'"'+(s.appearanceMode===modeOptions[i][0]?" selected":"")+'>'+esc(modeOptions[i][1])+'</option>';
    mo+='</select><label class="field">'+esc(translate("theme"))+' ('+(s.themeIndex+1)+' / '+window.PARIN_THEMES.length+')</label><select data-setting="themeIndex">';
    for(var j=0;j<window.PARIN_THEMES.length;j++)mo+='<option value="'+j+'"'+(s.themeIndex===j?" selected":"")+'>'+esc(window.PARIN_THEMES[j].name)+'</option>';
    mo+='</select>'+settingRow("glass","glass_sub",s.glass)+'<label class="field">'+esc(translate("glass"))+' • '+Math.round(s.glassOpacity*100)+'%</label><input type="range" min="30" max="90" value="'+Math.round(s.glassOpacity*100)+'" data-setting="glassOpacity">';
    out+=panel(translate("appearance"),mo);
    out+=panel(translate("study_preferences"),settingRow("animations",null,s.animations)+settingRow("haptics",null,s.haptics)+settingRow("auto_reveal",null,s.autoReveal)+(s.autoReveal?'<label class="field">'+esc(translate("auto_reveal_delay"))+' • '+(parseInt(s.autoRevealDelaySeconds,10)||3)+'s</label><input type="range" min="1" max="30" value="'+(parseInt(s.autoRevealDelaySeconds,10)||3)+'" data-setting="autoRevealDelaySeconds">':"")+settingRow("progress",null,s.showProgress)+settingRow("timer",null,s.showTimer)+settingRow("show_xp","show_xp_sub",s.showXp)+settingRow("confirm_exit","confirm_exit_sub",s.confirmExit)+settingRow("compact_settings","compact_settings_sub",s.compactSettings));
    out+=panel(translate("music"),settingRow("music_study",null,s.musicEnabled)+'<label class="field">'+esc(translate("music"))+'</label><select data-setting="musicTrack"><option value="lofi_night"'+(s.musicTrack==="lofi_night"?" selected":"")+'>Lo-fi Night</option><option value="rainy_focus"'+(s.musicTrack==="rainy_focus"?" selected":"")+'>Rainy Focus</option><option value="deep_focus"'+(s.musicTrack==="deep_focus"?" selected":"")+'>Deep Focus</option></select><label class="field">'+esc(translate("volume")||"Volume")+' • '+Math.round(s.musicVolume*100)+'%</label><input type="range" min="0" max="100" value="'+Math.round(s.musicVolume*100)+'" data-setting="musicVolume"><div class="row wrap" style="margin-top:9px">'+btn(esc(translate("music_btn")),"toggle-music")+'</div>');
    out+=panel(translate("daily_goal"),'<label class="field">'+esc(translate("daily_goal"))+' (5–100)</label><input type="number" min="5" max="100" value="'+s.dailyGoal+'" data-setting="dailyGoal">');
    out+=panel(translate("backup"),'<div class="row wrap">'+btn(esc(translate("export")),"export-backup","","button primary")+' '+btn(esc(translate("import")),"import-backup")+'</div>');
    out+=panel(translate("extra"),'<div class="row wrap">'+btn(esc(translate("achievement_center")),"goto",' data-page="achievements"')+' '+btn(esc(translate("smart_mix")),"goto",' data-page="power"')+' '+btn(esc(translate("about")),"goto",' data-page="about"')+'</div>');
    return out;
  }
  function languageOptions(selected) {
    var s="";
    for(var i=0;i<languages.length;i++)s+='<option value="'+languages[i][0]+'"'+(languages[i][0]===selected?" selected":"")+'>'+esc(languages[i][1])+'</option>';
    return s;
  }
  function renderStats() {
    var st=stats(),week=weekReviews(),out=pageHead(translate("experience"),translate("achievement_center_sub"));
    out+='<div class="grid">'+metric(st.total,translate("cards"))+metric(st.reviews,translate("reviews")||"Reviews")+metric(st.due,translate("cards_ready"))+metric(st.favorites,translate("favorite_only"))+'</div>';
    out+=panel(translate("today"),'<div class="row between"><strong>'+state.xp+' XP</strong><span class="muted">Level '+(1+Math.floor(state.xp/250))+' • '+(state.xp%250)+' / 250</span></div>'+progressBar((state.xp%250)/250)+'<p class="muted">'+esc(translate("week_reviews")||"Reviews this week")+': '+week+' • '+esc(translate("streak")||"Streak")+': '+state.streak+'</p>');
    out+='<h2 class="section-title">'+esc(translate("boxes"))+'</h2>';
    for(var d=0;d<state.decks.length;d++){
      var deck=state.decks[d];out+=panel(deck.name,boxStatsHtml(deck));
    }
    out+=panel(translate("achievement_center"),'<div class="row wrap">'+btn(esc(translate("achievement_center")),"goto",' data-page="achievements"',"button primary")+'</div>');
    return out;
  }
  function boxStatsHtml(deck) {
    var out="",total=Math.max(1,deck.cards.length);
    for(var i=0;i<deck.boxes.length;i++){
      var n=0;for(var j=0;j<deck.cards.length;j++)if(deck.cards[j].box===i)n++;
      out+='<div class="bar-row"><div class="row between"><span>'+esc(deck.boxes[i].name)+'</span><span class="muted">'+n+'</span></div><div class="bar-track"><div class="bar-fill" style="width:'+(n/total*100)+'%;background:'+colorFromValue(deck.boxes[i].color)+'"></div></div></div>';
    }
    return out;
  }
  function renderAchievements() {
    var st=stats(),items=[
      [translate("ach_first_steps"),translate("ach_first_steps_desc"),st.total,1],
      [translate("ach_card_builder"),translate("ach_card_builder_desc"),st.total,25],
      [translate("ach_reviewer"),translate("ach_reviewer_desc"),st.reviews,50],
      [translate("ach_dedicated"),translate("ach_dedicated_desc"),st.reviews,200],
      [translate("ach_collector"),translate("ach_collector_desc"),st.favorites,10],
      [translate("ach_deck_master"),translate("ach_deck_master_desc"),state.decks.length,5],
      [translate("ach_box_explorer"),translate("ach_box_explorer_desc"),st.boxes,10],
      [translate("ach_centurion"),translate("ach_centurion_desc"),st.reviews,1000]
    ];
    var unlocked=items.filter(function(b){return b[2]>=b[3];}).length;
    var today=dateKey(new Date()),challengeIndex=Math.floor((new Date().getTime()-new Date(new Date().getFullYear(),0,1).getTime())/86400000)%4,todayReviews=0;
    for(var i=0;i<state.reviewDays.length;i++)if(state.reviewDays[i]===today)todayReviews++;
    var challenges=[
      {title:translate("challenge_review_today").replace("{count}",state.settings.dailyGoal),value:todayReviews,target:state.settings.dailyGoal},
      {title:translate("challenge_favorite_3"),value:st.favorites,target:3},
      {title:translate("challenge_good_10"),value:state.dailyGoodRatingsDay===today?state.dailyGoodRatings:0,target:10},
      {title:translate("challenge_create_2"),value:state.dailyCardsCreatedDay===today?state.dailyCardsCreated:0,target:2}
    ];
    var challenge=challenges[challengeIndex],challengeValue=Math.min(challenge.value,challenge.target);
    var out=pageHead(translate("achievement_center"),translate("achievement_center_sub"));
    out+=panel(translate("achievement_center"),'<div class="row between"><strong>'+unlocked+' / '+items.length+' '+esc(translate("ach_badges"))+'</strong><span class="badge">'+state.streak+' '+esc(translate("streak_days"))+'</span></div>'+progressBar(unlocked/Math.max(1,items.length)));
    out+=panel(translate("today"),'<div class="panel-title">'+esc(challenge.title)+'</div><div class="row between" style="margin-top:8px"><span>'+challengeValue+' / '+challenge.target+'</span><span class="muted">'+Math.round(challengeValue/Math.max(1,challenge.target)*100)+'%</span></div>'+progressBar(challengeValue/Math.max(1,challenge.target)));
    out+=panel(translate("experience"),'<div class="grid">'+metric(st.total,translate("cards"))+metric(st.reviews,translate("reviews"))+metric(st.favorites,translate("favorite_only"))+metric(st.due,translate("cards_ready"))+'</div>');
    out+='<h2 class="section-title">'+esc(translate("ach_badges"))+'</h2>';
    for(var j=0;j<items.length;j++){
      var b=items[j],done=b[2]>=b[3],value=Math.min(b[2],b[3]);
      out+=panel((done?"✓ ":"○ ")+b[0],'<div class="muted">'+esc(b[1])+'</div><div class="row between" style="margin-top:8px"><span>'+value+' / '+b[3]+'</span><span class="badge">'+esc(translate(done?"ach_unlocked":"ach_in_progress"))+'</span></div>'+progressBar(value/Math.max(1,b[3]),done?"#43a047":primaryColor()));
    }
    return out;
  }
  function renderPowerCenter() {
    var st=stats(),out=pageHead(translate("power_center"),translate("smart_mix_sub"));
    var level=1+Math.floor(state.xp/250),levelXp=state.xp%250;
    var hard=0,medium=0,fresh=0,easy=0;
    for(var i=0;i<st.cards.length;i++){
      var c=st.cards[i].card,difficulty=c.difficulty||"auto";
      if(difficulty==="hard"||(difficulty==="auto"&&((c.lapses||0)>=3||((c.reviews||0)>=4&&(c.box||0)<=1))))hard++;
      else if(difficulty==="medium")medium++;
      else if(difficulty==="easy"||(difficulty==="auto"&&(c.box||0)>=3&&!(c.lapses||0)))easy++;
      else if(difficulty==="auto"&&(c.reviews||0)<=1)fresh++;
      else medium++;
    }
    var today=dateKey(new Date()),reward=50+Math.min(state.streak*5,100);
    out+=panel(translate("today"),'<div class="grid">'+metric(st.due,translate("cards_ready"))+metric(state.settings.dailyGoal,translate("daily_goal"))+metric(state.xp,"XP")+metric(translate("level")+" "+level,translate("level"))+'</div><div style="margin-top:10px">'+progressBar(levelXp/250)+'</div><p class="muted">'+levelXp+' / 250 XP • '+esc(translate("week_reviews"))+': '+weekReviews()+'</p>');
    out+=panel(translate("pc_daily_reward"),'<p class="muted">'+esc(state.lastRewardDay===today?translate("pc_reward_already_claimed"):translate("pc_reward_ready"))+'</p><div class="row between"><strong>'+esc(translate("pc_up_to_xp"))+' +'+reward+' XP</strong>'+btn(esc(translate("pc_claim_reward")),"claim-reward","","button primary")+'</div>');
    var mix='<p class="muted">'+esc(translate("smart_mix_sub"))+'</p><label class="field" for="smart-mix-size">'+esc(translate("cards"))+'</label><select id="smart-mix-size"><option value="10"'+(smartMixSize===10?" selected":"")+'>'+
      '10</option><option value="20"'+(smartMixSize===20?" selected":"")+'>'+
      '20</option><option value="30"'+(smartMixSize===30?" selected":"")+'>'+
      '30</option></select><label class="field" for="smart-mix-filter">'+esc(translate("smart_mix_filter"))+'</label><select id="smart-mix-filter">'+
      '<option value="all"'+(smartMixFilter==="all"?" selected":"")+'>'+esc(translate("filter_all"))+'</option>'+
      '<option value="due"'+(smartMixFilter==="due"?" selected":"")+'>'+esc(translate("filter_due"))+'</option>'+
      '<option value="hard"'+(smartMixFilter==="hard"?" selected":"")+'>'+esc(translate("filter_hard"))+'</option>'+
      '<option value="medium"'+(smartMixFilter==="medium"?" selected":"")+'>'+esc(translate("filter_medium"))+'</option>'+
      '<option value="easy"'+(smartMixFilter==="easy"?" selected":"")+'>'+esc(translate("filter_easy"))+'</option></select><div style="margin-top:10px">'+btn(esc(translate("smart_mix")),"smart-mix","","button primary")+'</div>';
    out+=panel(translate("smart_mix"),mix);
    var dots='<div class="row wrap">';
    for(var dayIndex=27;dayIndex>=0;dayIndex--){
      var day=new Date();day.setHours(0,0,0,0);day.setDate(day.getDate()-dayIndex);
      var key=dateKey(day),done=state.reviewDays.indexOf(key)>=0;
      dots+='<span title="'+attr(key)+'" style="display:inline-block;width:19px;height:19px;border-radius:0;background:'+(done?primaryColor():'rgba(120,130,150,.18)')+';border:1px solid rgba(120,130,150,.18)"></span>';
    }
    dots+='</div><p class="muted">'+state.streak+' '+esc(translate("streak_days"))+' • '+uniqueDays()+' '+esc(translate("pc_study_days"))+'</p>';
    out+=panel(translate("pc_streak_calendar"),dots);
    out+=panel(translate("pc_weekly_challenge"),'<div class="row between"><strong>'+esc(translate("pc_complete_40_reviews"))+'</strong><span class="muted">'+Math.min(weekReviews(),40)+' / 40</span></div><div style="margin-top:10px">'+progressBar(Math.min(1,weekReviews()/40))+'</div>');
    out+=panel(translate("pc_smart_difficulty"),'<div class="grid">'+metric(hard,translate("hard"))+metric(medium,translate("difficulty_medium"))+metric(fresh,translate("new_card"))+metric(easy,translate("easy"))+'</div>');
    var levelRows=[[1,"pc_level_getting_started"],[3,"pc_level_consistent"],[5,"pc_level_focus"],[10,"pc_level_pro"]],rewards='';
    for(var ri=0;ri<levelRows.length;ri++){
      var unlocked=level>=levelRows[ri][0];
      rewards+='<div class="setting-row"><span class="setting-copy"><span class="setting-name">'+(unlocked?"✓ ":"🔒 ")+esc(translate(levelRows[ri][1]))+'</span></span><span class="badge">'+esc(translate("level"))+' '+levelRows[ri][0]+'</span></div>';
    }
    out+=panel(translate("pc_level_rewards"),rewards);
    out+=panel(translate("achievement_center"),'<div class="row wrap">'+btn(esc(translate("achievement_center")),"goto",' data-page="achievements"',"button primary")+'</div>');
    return out;
  }
  function renderAbout() {
    var out=pageHead(translate("about"),"Parin Litner");
    out+=panel("Parin Litner",'<p>'+esc(translate("about_creator_desc"))+'</p><p class="muted">'+esc(translate("about_ai"))+'</p><p class="muted">'+esc(translate("about_love"))+'</p>'+btn(esc(translate("about_github")),"open-repository","","button primary"));
    out+=panel(translate("about_version_title"),'<div class="muted">7.2.0 • '+esc(translate("about_android_compat"))+'</div>');
    return out;
  }
  function weekReviews() {
    var now=new Date(),day=(now.getDay()+6)%7,start=new Date(now.getFullYear(),now.getMonth(),now.getDate()-day);
    return state.reviewDays.filter(function(k){var d=new Date(k+"T00:00:00");return !isNaN(d.getTime())&&d>=start&&d<=now;}).length;
  }
  function uniqueDays() {
    var s={};for(var i=0;i<state.reviewDays.length;i++)s[state.reviewDays[i]]=1;return Object.keys(s).length;
  }
  function colorFromValue(value) {
    var n=Number(value);if(isNaN(n))return primaryColor();var hex=(n>>>0).toString(16);while(hex.length<8)hex="0"+hex;return "#"+hex.slice(2);
  }
  function imageUrl(value) {
    var x=text(value).replace(/\s/g,"");
    if(x.indexOf("data:image/")===0)return x;
    var mime="image/jpeg";
    if(x.indexOf("iVBORw0KGgo")===0)mime="image/png";
    else if(x.indexOf("R0lGOD")===0)mime="image/gif";
    else if(x.indexOf("UklGR")===0)mime="image/webp";
    return "data:"+mime+";base64,"+x;
  }
  function bindSearch() {
    var boxes=CONTENT.querySelectorAll(".search-box");
    for(var i=0;i<boxes.length;i++) boxes[i].oninput=function(){
      var q=this.value.toLowerCase(),items=CONTENT.querySelectorAll("[data-filter]");
      for(var j=0;j<items.length;j++)items[j].style.display=items[j].getAttribute("data-filter").indexOf(q)>=0?"":"none";
      searchTerm=this.value;
    };
  }
  function effectiveCardDifficulty(card) {
    var difficulty = card && card.difficulty ? card.difficulty : "auto";
    if (difficulty === "hard" || difficulty === "medium" || difficulty === "easy") return difficulty;
    if ((card.lapses || 0) >= 3 || ((card.reviews || 0) >= 4 && (card.box || 0) <= 1)) return "hard";
    if ((card.box || 0) >= 3 && !(card.lapses || 0)) return "easy";
    return "medium";
  }
  function promptStudyDifficulty(refs, label) {
    var base = refs;
    if (!base) {
      base = [];
      var allStats = stats();
      for (var i = 0; i < allStats.cards.length; i++) {
        if (isDue(allStats.cards[i].card)) {
          base.push({ deckId: allStats.cards[i].deck.id, cardId: allStats.cards[i].card.id });
        }
      }
    }
    if (!base.length) {
      showModal(translate("study"), '<p>' + esc(translate("no_due")) + '</p>', [
        { label: translate("close"), action: "close-modal" }
      ]);
      return;
    }
    pendingStudyRefs = base.slice(0);
    pendingStudyLabel = label || translate("study");
    showModal(translate("card_difficulty"), '<p>' + esc(translate("study_difficulty_hint")) + '</p>', [
      { label: translate("difficulty_all"), action: "study-difficulty", extra: ' data-difficulty="all"', primary: true },
      { label: translate("hard"), action: "study-difficulty", extra: ' data-difficulty="hard"' },
      { label: translate("difficulty_medium"), action: "study-difficulty", extra: ' data-difficulty="medium"' },
      { label: translate("easy"), action: "study-difficulty", extra: ' data-difficulty="easy"' },
      { label: translate("cancel"), action: "close-modal" }
    ]);
  }
  function startStudyWithDifficulty(difficulty) {
    var filtered = [], refs = pendingStudyRefs || [];
    for (var i = 0; i < refs.length; i++) {
      var card = getCard(refs[i].deckId, refs[i].cardId);
      if (card && (difficulty === "all" || effectiveCardDifficulty(card) === difficulty)) filtered.push(refs[i]);
    }
    var label = pendingStudyLabel;
    pendingStudyRefs = null;
    pendingStudyLabel = "";
    closeModal();
    if (!filtered.length) {
      showModal(translate("study"), '<p>' + esc(translate("no_review")) + '</p>', [
        { label: translate("close"), action: "close-modal" }
      ]);
      return;
    }
    startStudy(filtered, label);
  }

  function startStudy(refs, label) {
    if(session)stopStudyTimer();
    var picked=refs||[],cards=[];
    if(!refs) {
      var st=stats();
      for(var i=0;i<st.cards.length;i++)if(isDue(st.cards[i].card))cards.push({deckId:st.cards[i].deck.id,cardId:st.cards[i].card.id});
    } else cards=picked.slice(0);
    if(!cards.length){showModal(translate("study"),'<p>'+esc(translate("no_due"))+'</p>',[{label:translate("close"),action:"close-modal"}]);return;}
    for(var j=cards.length-1;j>0;j--){var k=Math.floor(Math.random()*(j+1)),tmp=cards[j];cards[j]=cards[k];cards[k]=tmp;}
    session={cards:cards,index:0,revealed:false,seconds:0,finished:false,label:label||translate("study"),startedAt:new Date().getTime()};
    goto("study",{});
    if(state.settings.musicEnabled){Native.playMusic(state.settings.musicTrack,state.settings.musicVolume);musicPlaying=true;}
    if(state.settings.showTimer)startStudyTimer();
    scheduleAutoReveal();
  }
  function scheduleAutoReveal() {
    if(autoRevealHandle){window.clearTimeout(autoRevealHandle);autoRevealHandle=null;}
    if(!state.settings.autoReveal||!session||session.finished||session.revealed)return;
    var expected=session,expectedIndex=session.index;
    var delay=Math.max(1,Math.min(30,parseInt(state.settings.autoRevealDelaySeconds,10)||3))*1000;
    autoRevealHandle=window.setTimeout(function(){
      autoRevealHandle=null;
      if(session===expected&&session.index===expectedIndex&&!session.finished&&!session.revealed){session.revealed=true;render();}
    },delay);
  }
  function startStudyTimer() {
    stopStudyTimer();
    studyInterval=window.setInterval(function(){
      if(session&&!session.finished){session.seconds++;var el=document.getElementById("study-clock");if(el)el.textContent=duration(session.seconds);}
    },1000);
  }
  function stopStudyTimer(){if(studyInterval){window.clearInterval(studyInterval);studyInterval=null;}}
  function finishStudy() {
    if(!session)return;session.finished=true;stopStudyTimer();persist();
    showModal(translate("done"),'<p>'+esc(session.cards.length+" "+translate("cards_count"))+'</p><p>'+esc(duration(session.seconds))+'</p>',[{label:translate("great"),action:"finish-study",primary:true}]);
  }
  function rateCard(rating) {
    if(!session||session.finished||!session.revealed)return;
    var ref=session.cards[session.index],c=getCard(ref.deckId,ref.cardId),d=getDeck(ref.deckId);if(!c||!d)return;
    if(autoRevealHandle){window.clearTimeout(autoRevealHandle);autoRevealHandle=null;}
    var last=Math.max(0,d.boxes.length-1),now=new Date();c.reviews=(c.reviews||0)+1;
    if(rating===0){c.lapses=(c.lapses||0)+1;c.box=0;c.due=new Date(now.getTime()+10*60000).toISOString();}
    else if(rating===1){c.box=Math.max(0,Math.min(last,c.box));c.due=new Date(now.getTime()+86400000).toISOString();}
    else if(rating===2){c.box=Math.min(last,Math.max(0,c.box+1));var good=[1,2,4,7,14,30];c.due=new Date(now.getTime()+good[Math.min(c.box,5)]*86400000).toISOString();}
    else {c.box=Math.min(last,Math.max(0,c.box+2));var easy=[2,4,7,14,30,60];c.due=new Date(now.getTime()+easy[Math.min(c.box,5)]*86400000).toISOString();}
    recordReview();persist();
    if(state.settings.haptics){try{Native.vibrate(rating===0?35:18);}catch(e){}}
    if(state.settings.showXp)notify("+12 XP");
    if(session.index>=session.cards.length-1){finishStudy();return;}
    session.index++;session.revealed=false;render();
    scheduleAutoReveal();
  }
  function recordReview(rating) {
    var now=new Date(),today=dateKey(now),yesterday=dateKey(new Date(now.getFullYear(),now.getMonth(),now.getDate()-1));
    state.xp+=12;
    if(state.lastStudyDay===today){} else if(state.lastStudyDay===yesterday)state.streak+=1;else state.streak=1;
    state.lastStudyDay=today;state.reviewDays.push(today);if(state.reviewDays.length>300)state.reviewDays=state.reviewDays.slice(-300);
    if(state.dailyGoodRatingsDay!==today){state.dailyGoodRatingsDay=today;state.dailyGoodRatings=0;}
    if(rating===2)state.dailyGoodRatings++;
  }
  function pauseFocusForNavigation() {
    if(focusInterval){window.clearInterval(focusInterval);focusInterval=null;}
    if(focusRunning){focusRunning=false;try{Native.pauseMusic();}catch(e){}musicPlaying=false;}
  }
  function tickFocus() {
    if(!focusRunning)return;
    focusRemaining--;
    var el=document.getElementById("focus-clock");
    if(el)el.textContent=duration(focusRemaining);
    if(focusRemaining<=0){
      pauseFocusForNavigation();focusRemaining=0;persist();
      try{Native.playAlarm();}catch(e){}
      if(state.settings.musicEnabled)Native.stopMusic();
      notify(translate("focus_done"));
      showModal(translate("focus_done"),'<p>'+esc(translate("great"))+'</p>',[{label:translate("close"),action:"close-modal"}]);
    }
  }
  function toggleMusic() {
    if(musicPlaying){try{Native.pauseMusic();}catch(e){}musicPlaying=false;notify(translate("pause"));}
    else {try{Native.playMusic(state.settings.musicTrack,state.settings.musicVolume);musicPlaying=true;notify(translate("music_btn"));}catch(e){notify(translate("image_error"));}}
    render();
  }
  function createBackupPayload() {
    var assets = [], decks = [], n = 0;
    // Copy only card metadata. Do not JSON-clone the original Base64 image
    // strings: duplicating every image can exhaust the small heap on Android 4.
    for (var di = 0; di < state.decks.length; di++) {
      var sourceDeck = state.decks[di], deck = {};
      for (var deckKey in sourceDeck) {
        if (!Object.prototype.hasOwnProperty.call(sourceDeck, deckKey)) continue;
        if (deckKey === "cards") continue;
        deck[deckKey] = deckKey === "boxes" ? clone(sourceDeck.boxes || []) : sourceDeck[deckKey];
      }
      deck.cards = [];
      var sourceCards = sourceDeck.cards || [];
      for (var ci = 0; ci < sourceCards.length; ci++) {
        var sourceCard = sourceCards[ci], card = {};
        for (var cardKey in sourceCard) {
          if (!Object.prototype.hasOwnProperty.call(sourceCard, cardKey)) continue;
          if (cardKey === "frontImage" || cardKey === "backImage") continue;
          card[cardKey] = sourceCard[cardKey];
        }
        ["front", "back"].forEach(function (side) {
          var key = side + "Image", data = sourceCard[key];
          if (data && typeof data === "string" && data.length) {
            var encoded = data;
            var dataPrefix = encoded.indexOf("base64,");
            if (dataPrefix >= 0) encoded = encoded.substring(dataPrefix + 7);
            if (/\s/.test(encoded)) encoded = encoded.replace(/\s/g, "");
            if (!encoded || !/^[A-Za-z0-9+/]*={0,2}$/.test(encoded) || encoded.length % 4 !== 0) {
              throw new Error("Invalid image data in card " + sourceCard.id);
            }
            n++;
            var name = "image_" + ("000000" + n).slice(-6) + ".bin";
            assets.push({ name: name, data: encoded });
            card[side + "ImageAsset"] = name;
          } else {
            card[side + "ImageAsset"] = null;
          }
        });
        deck.cards.push(card);
      }
      decks.push(deck);
    }
    var manifest = {
      app: "Parin Litner",
      format: 1,
      exportedAt: new Date().toISOString(),
      imageCount: assets.length,
      decks: decks
    };
    return { manifest: JSON.stringify(manifest), assets: assets };
  }

  function exportBackup() {
    var started = false;
    try {
      var payload = createBackupPayload();
      var result = Native.beginBackupExport(payload.manifest, "parin_litner_backup.plbackup");
      if (result !== "OK") throw new Error(translate("backup_error") || "Could not start writing the backup.");
      started = true;
      for (var i = 0; i < payload.assets.length; i++) {
        var asset = payload.assets[i];
        result = Native.appendBackupImage(asset.name, asset.data);
        if (result !== "OK") throw new Error(translate("backup_error") || "Could not write an image to the backup.");
      }
      result = Native.finishBackupExport();
      started = false;
      if (!result || result === "ERROR") throw new Error(translate("backup_error") || "Could not finish the backup.");
      notify(translate("backup_saved") || "Backup saved successfully");
    } catch (e) {
      if (started) {
        try { Native.cancelBackupExport(); } catch (ignored) {}
      }
      var detail = e && e.message ? e.message : "";
      notify((translate("backup_error") || "Backup export failed") + (detail ? " • " + detail : ""));
    }
  }
  function importBackupBinary(binary) {
    if(binary.indexOf("PLITBK01")===0){
      if(binary.length<12)throw new Error("Backup file is incomplete.");
      var manifestLen=read32(binary,8);
      if(manifestLen>64*1024*1024||manifestLen>binary.length-12)throw new Error("Backup metadata length is invalid.");
      var manifest=parseJson(decodeUtf8(binary.substring(12,12+manifestLen)),null);
      if(!manifest||manifest.app!=="Parin Litner"||manifest.format!==1)throw new Error("Unsupported backup format.");
      var count=parseInt(manifest.imageCount,10);
      if(isNaN(count)||count<0||count>50000)throw new Error("Invalid image count.");
      var off=12+manifestLen,assets={};
      for(var i=0;i<count;i++){
        if(off+2>binary.length)throw new Error("Backup image table is incomplete.");
        var nameLen=read16(binary,off);off+=2;
        if(nameLen===0||off+nameLen+4>binary.length)throw new Error("Invalid image entry.");
        var name=decodeUtf8(binary.substring(off,off+nameLen));off+=nameLen;
        var len=read32(binary,off);off+=4;
        if(len>binary.length-off||assets[name]!==undefined)throw new Error("Image data is incomplete or duplicated.");
        assets[name]=binary.substring(off,off+len);off+=len;
      }
      if(off!==binary.length)throw new Error("Unexpected trailing backup data.");
      if(Object.prototype.toString.call(manifest.decks)!=="[object Array]")throw new Error("Backup does not contain decks.");
      for(var d=0;d<manifest.decks.length;d++){
        var deck=manifest.decks[d];if(!deck.cards||Object.prototype.toString.call(deck.cards)!=="[object Array]")throw new Error("Invalid card list.");
        for(var c=0;c<deck.cards.length;c++){
          var card=deck.cards[c];
          ["front","back"].forEach(function(side){
            var ref=card[side+"ImageAsset"];
            if(ref!==null&&ref!==undefined){
              if(typeof ref!=="string"||assets[ref]===undefined)throw new Error("A card image is missing from backup.");
              card[side+"Image"]=base64OfBinary(assets[ref]);
            } else card[side+"Image"]=null;
            delete card[side+"ImageAsset"];
          });
        }
      }
      return manifest.decks;
    }
    var decoded=parseJson(decodeUtf8(binary),null);
    var decks=decoded&&decoded.decks?decoded.decks:decoded;
    if(Object.prototype.toString.call(decks)!=="[object Array]")throw new Error("Selected file is not a valid backup.");
    return decks;
  }
  function read16(s,off){return ((s.charCodeAt(off)&255)<<8)|(s.charCodeAt(off+1)&255);}
  function read32(s,off){return (((s.charCodeAt(off)&255)<<24)|((s.charCodeAt(off+1)&255)<<16)|((s.charCodeAt(off+2)&255)<<8)|(s.charCodeAt(off+3)&255))>>>0;}
  function importBackupBase64(b64,name) {
    try {
      var binary=window.atob(b64.replace(/\s/g,""));
      pendingImport=importBackupBinary(binary).map(normalizeDeck).filter(function(d){return !!d;});
      if(!pendingImport.length){notify(translate("no_cards"));return;}
      showModal(translate("import"),'<p>'+esc(pendingImport.length+' '+translate("decks"))+'</p><p class="muted">'+esc(name||"")+'</p>',[
        {label:translate("cancel"),action:"close-modal"},
        {label:translate("merge"),action:"merge-import"},
        {label:translate("replace"),action:"replace-import",primary:true}
      ]);
    } catch(e) {pendingImport=null;notify(translate("backup_invalid")||e.message||"Invalid backup");}
  }
  function openImportDialog() {
    var list=[];
    try{list=JSON.parse(Native.listBackupFiles()||"[]");}catch(e){}
    var body='<p>'+esc(translate("import"))+' • .plbackup / .json</p>';
    body+='<div class="row wrap">'+btn(esc(translate("choose_file")||"Choose file"),"pick-backup-file","","button primary")+'</div>';
    if(list.length){
      body+='<label class="field">'+esc(translate("backup") )+' • Downloads</label><select id="backup-file">';
      for(var i=0;i<list.length;i++)body+='<option value="'+attr(list[i])+'">'+esc(list[i])+'</option>';
      body+='</select><div style="margin-top:8px">'+btn(esc(translate("import")),"import-from-download","","button primary")+'</div>';
    }else body+='<p class="muted">'+esc(translate("no_cards"))+'</p>';
    showModal(translate("import"),body,[{label:translate("close"),action:"close-modal"}]);
  }
  function showImportDownloads() {
    var el=document.getElementById("backup-file");if(!el)return;
    downloadedBackupName=el.value;
    var b64="";
    try{b64=Native.readBackupFile(downloadedBackupName);}catch(e){}
    if(!b64){notify(translate("backup_invalid"));return;}
    closeModal();importBackupBase64(b64,downloadedBackupName);
  }
  function onPickedBackup() {
    var raw="";
    try{raw=Native.consumePickedFile();}catch(e){}
    if(!raw){notify(translate("backup_invalid"));return;}
    var picked=parseJson(raw,null);
    if(!picked||!picked.base64){notify(translate("backup_invalid"));return;}
    importBackupBase64(picked.base64,picked.name);
  }
  function applyImport(replace) {
    if(!pendingImport)return;
    if(replace)state.decks=pendingImport;
    else {
      for(var i=0;i<pendingImport.length;i++){
        var d=clone(pendingImport[i]);d.id=uid();state.decks.push(normalizeDeck(d));
      }
    }
    pendingImport=null;closeModal();persist();view={page:"home"};navStack=[];render();notify(translate("done"));
  }
  function onPickedImage() {
    var raw="";
    try{raw=Native.consumePickedFile();}catch(e){}
    var picked=parseJson(raw,null);
    if(!picked||!picked.base64){return;}
    var d=getDeck(editCardDeckId);
    if(!d)return;
    var image=picked.base64.replace(/^data:image\/[a-zA-Z0-9.+-]+;base64,/,"");
    if(imageTarget==="front")d._editingFrontImage=image;
    else d._editingBackImage=image;
    render();
  }
  function handleAction(target) {
    var action=target.getAttribute("data-action"),id=target.getAttribute("data-id"),deckId=target.getAttribute("data-deck"),index=parseInt(target.getAttribute("data-index"),10);
    if(!action)return;
    if(action==="back"){back();return;}
    if(action==="backdrop-close"){return;}
    if(action==="close-modal"){closeModal();return;}
    if(action==="goto"){goto(target.getAttribute("data-page"));return;}
    if(action==="open-deck"){searchTerm="";goto("deck",{deckId:id});return;}
    if(action==="new-deck"){editDeckId=null;goto("deckEdit");return;}
    if(action==="edit-deck"){editDeckId=id;goto("deckEdit");return;}
    if(action==="delete-deck"){var deck=getDeck(id);if(deck)showModal(translate("delete"),'<p>'+esc(deck.name)+'</p>',[{label:translate("cancel"),action:"close-modal"},{label:translate("delete"),action:"confirm-delete-deck",extra:' data-id="'+attr(id)+'"',primary:true}]);return;}
    if(action==="confirm-delete-deck"){state.decks=state.decks.filter(function(d){return d.id!==id;});closeModal();persist();view={page:"home"};navStack=[];render();return;}
    if(action==="new-card"){editCardDeckId=target.getAttribute("data-deck")||id;editCardId=null;var d=getDeck(editCardDeckId);if(d){delete d._editingFrontImage;delete d._editingBackImage;goto("cardEdit");}return;}
    if(action==="edit-card"){editCardDeckId=deckId;editCardId=id;var c=getCard(deckId,id),d2=getDeck(deckId);if(c&&d2){d2._editingFrontImage=c.frontImage;d2._editingBackImage=c.backImage;goto("cardEdit");}return;}
    if(action==="delete-card"){var c2=getCard(deckId,id);if(c2)showModal(translate("delete_card"),'<p>'+esc(translate("delete_card_confirm"))+'</p>',[{label:translate("cancel"),action:"close-modal"},{label:translate("delete"),action:"confirm-delete-card",extra:' data-deck="'+attr(deckId)+'" data-id="'+attr(id)+'"',primary:true}]);return;}
    if(action==="confirm-delete-card"){var d3=getDeck(deckId);if(d3)d3.cards=d3.cards.filter(function(c){return c.id!==id;});closeModal();persist();render();return;}
    if(action==="favorite-card"){var fav=getCard(deckId,id);if(fav){fav.favorite=!fav.favorite;persist();render();}return;}
    if(action==="study-deck"){
      var deckChoice=getDeck(id);
      if(deckChoice){
        var dueCountNow=0,favCountNow=0;
        for(var dc=0;dc<deckChoice.cards.length;dc++){if(isDue(deckChoice.cards[dc]))dueCountNow++;if(deckChoice.cards[dc].favorite)favCountNow++;}
        showModal(translate("study_type"),'<p>'+esc(deckChoice.name)+'</p>',[
          {label:translate("cards_ready")+" ("+dueCountNow+")",action:"study-deck-mode",extra:' data-id="'+attr(id)+'" data-mode="due"',primary:true},
          {label:translate("all")+" ("+deckChoice.cards.length+")",action:"study-deck-mode",extra:' data-id="'+attr(id)+'" data-mode="all"'},
          {label:translate("favorite_only")+" ("+favCountNow+")",action:"study-deck-mode",extra:' data-id="'+attr(id)+'" data-mode="favorites"'},
          {label:translate("cancel"),action:"close-modal"}
        ]);
      }
      return;
    }
    if(action==="study-deck-mode"){
      var chosenDeck=getDeck(id),mode=target.getAttribute("data-mode"),refs=[];
      closeModal();
      if(chosenDeck){
        for(var ci=0;ci<chosenDeck.cards.length;ci++){
          var chosenCard=chosenDeck.cards[ci];
          if(mode==="all"||(mode==="favorites"&&chosenCard.favorite)||(mode==="due"&&isDue(chosenCard)))refs.push({deckId:chosenDeck.id,cardId:chosenCard.id});
        }
        promptStudyDifficulty(refs,chosenDeck.name);
      }
      return;
    }
    if(action==="study-all"){promptStudyDifficulty(null,translate("study"));return;}
    if(action==="study-difficulty"){startStudyWithDifficulty(target.getAttribute("data-difficulty")||"all");return;}
    if(action==="reveal"){if(session&&!session.finished){if(autoRevealHandle){window.clearTimeout(autoRevealHandle);autoRevealHandle=null;}session.revealed=true;render();}return;}
    if(action==="rate"){rateCard(parseInt(target.getAttribute("data-rating"),10)||0);return;}
    if(action==="zoom-study-image"){zoomStudyImage();return;}
    if(action==="zoom-study-in"){zoomScale=Math.min(6,zoomScale+0.5);applyStudyZoom();return;}
    if(action==="zoom-study-out"){zoomScale=Math.max(1,zoomScale-0.5);applyStudyZoom();return;}
    if(action==="finish-study"){closeModal();session=null;stopStudyTimer();backAfterStudy();return;}
    if(action==="confirm-study-exit"){closeModal();stopStudyTimer();session=null;back();return;}
    if(action==="manage-boxes"){goto("boxes",{deckId:id});return;}
    if(action==="delete-box"){deleteBox(index);return;}
    if(action==="add-box"){addBox();return;}
    if(action==="export-backup"){exportBackup();return;}
    if(action==="import-backup"){openImportDialog();return;}
    if(action==="pick-backup-file"){closeModal();try{Native.pickBackupFile();}catch(e){notify(translate("backup_invalid"));}return;}
    if(action==="import-from-download"){showImportDownloads();return;}
    if(action==="merge-import"){applyImport(false);return;}
    if(action==="replace-import"){applyImport(true);return;}
    if(action==="pick-image"){imageTarget=target.getAttribute("data-side")||"front";try{Native.pickImage();}catch(e){notify(translate("image_error"));}return;}
    if(action==="clear-image"){var dx=getDeck(editCardDeckId);if(dx){if(target.getAttribute("data-side")==="front")dx._editingFrontImage=null;else dx._editingBackImage=null;render();}return;}
    if(action==="focus-duration"){if(!focusRunning){focusDuration=parseInt(target.getAttribute("data-minutes"),10)||30;focusRemaining=focusDuration*60;render();}return;}
    if(action==="focus-custom"){
      if(!focusRunning){
        showModal(translate("custom_minutes"),
          '<label class="field" for="custom-focus-minutes">'+esc(translate("enter_minutes"))+'</label><input id="custom-focus-minutes" type="number" min="1" max="600" value="'+focusDuration+'"><p class="muted">'+esc(translate("minutes_range"))+'</p>',
          [{label:translate("cancel"),action:"close-modal"},{label:translate("save"),action:"focus-custom-apply",primary:true}]);
      }
      return;
    }
    if(action==="focus-custom-apply"){
      var customInput=document.getElementById("custom-focus-minutes"),customMinutes=parseInt(customInput?customInput.value:"",10);
      if(customMinutes>=1&&customMinutes<=600){focusDuration=customMinutes;focusRemaining=customMinutes*60;closeModal();render();}
      else{notify(translate("minutes_range"));}
      return;
    }
    if(action==="focus-toggle"){toggleFocus();return;}
    if(action==="focus-reset"){pauseFocusForNavigation();focusRemaining=focusDuration*60;render();return;}
    if(action==="toggle-music"){toggleMusic();return;}
    if(action==="claim-reward"){claimReward();return;}
    if(action==="smart-mix"){smartMix();return;}
    if(action==="open-repository"){try{Native.openUrl("https://github.com/Parin-M/parin-litner");}catch(e){}return;}
    if(action==="confirm-close"){closeModal();return;}
  }
  function backAfterStudy() {
    if(navStack.length)view=navStack.pop();else view={page:"home"};
    render();setCanGoBack();
  }
  function deleteBox(index) {
    var d=getDeck(view.params.deckId);if(!d||d.boxes.length<=1||isNaN(index)||index<0||index>=d.boxes.length)return;
    showModal(translate("delete_box"),'<p>'+esc(translate("delete_box_confirm"))+'</p>',[
      {label:translate("cancel"),action:"close-modal"},
      {label:translate("delete"),action:"confirm-delete-box",extra:' data-index="'+index+'"',primary:true}
    ]);
  }
  function addBox() {
    var el=document.getElementById("new-box-name"),name=el?el.value.trim():"",d=getDeck(view.params.deckId);
    if(!d||!name){notify(translate("box_name"));return;}
    d.boxes.push({id:uid(),name:name,color:parseInt(theme().primary.slice(1),16)+4278190080});
    persist();render();
  }
  function removeBox(index) {
    var d=getDeck(view.params.deckId);if(!d||d.boxes.length<=1||index<0||index>=d.boxes.length)return;
    d.boxes.splice(index,1);
    for(var i=0;i<d.cards.length;i++){if(d.cards[i].box===index)d.cards[i].box=0;else if(d.cards[i].box>index)d.cards[i].box--;}
    closeModal();persist();render();
  }
  function toggleFocus() {
    if(focusRunning){pauseFocusForNavigation();render();return;}
    focusRunning=true;focusStartedAt=new Date().getTime();
    if(state.settings.musicEnabled){try{Native.playMusic(state.settings.musicTrack,state.settings.musicVolume);musicPlaying=true;}catch(e){}}
    if(focusInterval)window.clearInterval(focusInterval);
    focusInterval=window.setInterval(tickFocus,1000);render();
  }
  function claimReward() {
    var today=dateKey(new Date());
    if(state.lastRewardDay===today){notify(translate("pc_reward_already_claimed"));return;}
    var points=50+Math.min(state.streak*5,100);
    state.lastRewardDay=today;state.xp+=points;persist();render();
    notify(translate("pc_reward_claimed")+" +"+points+" XP");
  }
  function inferredCardDifficulty(c) {
    var chosen=c.difficulty||"auto";
    if(chosen==="hard"||chosen==="medium"||chosen==="easy")return chosen;
    if((c.lapses||0)>=3||((c.reviews||0)>=4&&(c.box||0)<=1))return "hard";
    if((c.reviews||0)<=1)return "new_card";
    if((c.box||0)>=3&&!(c.lapses||0))return "easy";
    return "medium";
  }
  function smartMix() {
    if(!state.decks.length){notify(translate("no_cards"));return;}
    var sorted=state.decks.slice(0).sort(function(a,b){return b.cards.length-a.cards.length;});
    var deck=sorted[0],cards=deck.cards.slice(0);
    if(smartMixFilter==="due")cards=cards.filter(function(c){return isDue(c);});
    else if(["hard","medium","easy"].indexOf(smartMixFilter)>=0)cards=cards.filter(function(c){return inferredCardDifficulty(c)===smartMixFilter;});
    if(!cards.length){notify(translate("pc_no_cards_for_filter"));return;}
    function score(c){
      var value=0,difficulty=inferredCardDifficulty(c);
      if(isDue(c))value+=1000;
      value+=(c.lapses||0)*80;
      value+=Math.max(0,5-(c.box||0))*20;
      value+=Math.min(c.reviews||0,10);
      if(difficulty==="hard")value+=250;
      else if(difficulty==="medium")value+=100;
      else if(difficulty==="easy")value-=50;
      return value;
    }
    cards.sort(function(a,b){return score(b)-score(a);});
    var items=cards.slice(0,smartMixSize).map(function(c){return {deckId:deck.id,cardId:c.id};});
    promptStudyDifficulty(items,translate("smart_mix"));
  }
    function saveDeckForm(form) {
    var name=document.getElementById("deck-name").value.trim();
    if(!name){notify(translate("new_deck_hint"));return;}
    var desc=document.getElementById("deck-description").value.trim();
    var col=document.getElementById("deck-color").value;
    var d=editDeckId?getDeck(editDeckId):null;
    if(!d){d=normalizeDeck({id:uid(),name:name,description:desc,color:col,cards:[],boxes:defaultBoxes()});state.decks.unshift(d);}
    else{d.name=name;d.description=desc;d.color=col;}
    persist();replaceView("deck",{deckId:d.id});
  }
  function saveCardForm() {
    var d=getDeck(editCardDeckId);if(!d)return;
    var front=document.getElementById("front").value.trim(),backText=document.getElementById("back").value.trim();
    var frontImg=d._editingFrontImage||null,backImg=d._editingBackImage||null;
    if((!front&&!frontImg)||(!backText&&!backImg)){notify(translate("save_card"));return;}
    var card=editCardId?getCard(editCardDeckId,editCardId):null;
    if(!card){
      card=normalizeCard({id:uid(),front:front,back:backText,due:new Date().toISOString(),box:0});
      d.cards.unshift(card);
      var createdDay=dateKey(new Date());
      if(state.dailyCardsCreatedDay!==createdDay){state.dailyCardsCreatedDay=createdDay;state.dailyCardsCreated=0;}
      state.dailyCardsCreated++;
    }
    card.front=front;card.back=backText;card.tags=document.getElementById("card-tags").value.trim();
    card.box=parseInt(document.getElementById("card-box").value,10)||0;card.difficulty=document.getElementById("card-difficulty").value;card.favorite=document.getElementById("card-favorite").checked;
    card.frontImage=frontImg;card.backImage=backImg;
    delete d._editingFrontImage;delete d._editingBackImage;
    persist();replaceView("deck",{deckId:d.id});
  }
  function saveBoxes() {
    var d=getDeck(view.params.deckId);if(!d)return;
    for(var i=0;i<d.boxes.length;i++){
      var el=document.getElementById("boxname-"+i);if(el&&el.value.trim())d.boxes[i].name=el.value.trim();
    }
    persist();render();notify(translate("done"));
  }
  function handleSubmit(form) {
    var type=form.getAttribute("data-form");
    if(type==="deck"){saveDeckForm(form);return;}
    if(type==="card"){saveCardForm();return;}
    if(type==="boxes"){saveBoxes();return;}
    if(type==="boxadd"){addBox();return;}
  }
  function changeSetting(el) {
    var key=el.getAttribute("data-setting");if(!key)return;
    var val;
    if(el.type==="checkbox")val=el.checked;
    else if(key==="themeIndex"||key==="dailyGoal"||key==="autoRevealDelaySeconds")val=parseInt(el.value,10);
    else if(key==="glassOpacity")val=parseInt(el.value,10)/100;
    else if(key==="musicVolume")val=parseInt(el.value,10)/100;
    else val=el.value;
    if(key==="progress")key="showProgress";
    else if(key==="timer")key="showTimer";
    else if(key==="music_study")key="musicEnabled";
    else if(key==="show_xp")key="showXp";
    else if(key==="confirm_exit")key="confirmExit";
    else if(key==="compact_settings")key="compactSettings";
    else if(key==="auto_reveal")key="autoReveal";
    if(key==="languageCode"&&!window.PARIN_TRANSLATIONS[val])return;
    if(key==="appearanceMode"&&["light","dark","aero","amoled"].indexOf(val)<0)return;
    if(key==="musicTrack"&&["lofi_night","rainy_focus","deep_focus"].indexOf(val)<0)return;
    state.settings[key]=val;
    if(key==="haptics"&&val){try{Native.vibrate(80);}catch(e){}}
    if(key==="musicVolume"){try{Native.setMusicVolume(val);}catch(e){}}
    if(key==="musicEnabled"&&!val){try{Native.stopMusic();}catch(e){}musicPlaying=false;}
    if(key==="musicEnabled"&&val&&(view.page==="study"||view.page==="focus")){try{Native.playMusic(state.settings.musicTrack,state.settings.musicVolume);musicPlaying=true;}catch(e){}}
    persist();render();
  }
  function initEvents() {
    CONTENT.addEventListener("click",function(e){
      var target=e.target;
      while(target&&target!==CONTENT&&!target.getAttribute("data-action"))target=target.parentNode;
      if(target&&target!==CONTENT){e.preventDefault();handleAction(target);}
    });
    MODAL.addEventListener("click",function(e){
      var target=e.target;
      while(target&&target!==MODAL&&!target.getAttribute("data-action"))target=target.parentNode;
      if(target&&target!==MODAL){e.preventDefault();handleAction(target);}
    });
    CONTENT.addEventListener("submit",function(e){e.preventDefault();handleSubmit(e.target);});
    CONTENT.addEventListener("change",function(e){
      var el=e.target;
      if(el&&el.id==="smart-mix-size"){
        smartMixSize=parseInt(el.value,10)||20;
        if([10,20,30].indexOf(smartMixSize)<0)smartMixSize=20;
        render();
        return;
      }
      if(el&&el.id==="smart-mix-filter"){
        smartMixFilter=["all","due","hard","medium","easy"].indexOf(el.value)>=0?el.value:"all";
        render();
        return;
      }
      if(el&&el.getAttribute&&el.getAttribute("data-setting"))changeSetting(el);
    });
    CONTENT.addEventListener("input",function(e){
      var el=e.target;
      if(!el||!el.getAttribute)return;
      var key=el.getAttribute("data-setting");
      if(key==="glassOpacity"||key==="musicVolume"){
        var val=parseInt(el.value,10)/100;if(key==="glassOpacity")state.settings.glassOpacity=val;else state.settings.musicVolume=val;
        persist();
      }
    });
    // The settings gear is outside #content, so its click must be handled
    // explicitly. Without this listener it looked tappable but never opened.
    HEADER.addEventListener("click", function(e) {
      var target = e.target;
      while (target && target !== HEADER && !target.getAttribute("data-action")) {
        target = target.parentNode;
      }
      if (!target || target === HEADER) return;
      if (target.getAttribute("data-action") === "goto") {
        e.preventDefault();
        goto(target.getAttribute("data-page"));
      }
    });
    HEADER_BACK.onclick=function(){back();};
    document.getElementById("bottom-nav").onclick=function(e){
      var target=e.target;while(target&&target!==this&&!target.getAttribute("data-action"))target=target.parentNode;
      if(!target||target===this)return;
      var a=target.getAttribute("data-action");
      if(a==="goto"){goto(target.getAttribute("data-page"));return;}
      if(a==="study-all"){promptStudyDifficulty(null,translate("study"));return;}
    };
  }

  // Internal helper actions that are also called by event delegation.
  var originalHandleAction=handleAction;
  handleAction=function(target) {
    var action=target.getAttribute("data-action"),idx=parseInt(target.getAttribute("data-index"),10);
    if(action==="confirm-delete-box"){removeBox(idx);return;}
    originalHandleAction(target);
  };

  window.onNativePickedImage=onPickedImage;
  window.onNativePickedBackup=onPickedBackup;

  loadState();
  initEvents();
  render();
  persist();
}());
