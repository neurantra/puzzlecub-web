(() => {
 const workers = new Map();
 const empty = '{"move":null}';
 let assets;
 window.puzzlecubSearch = async raw => {
  const req = JSON.parse(raw);
  let slot = workers.get(req.id);
  if (!slot) {
   const worker = new Worker(new URL('ai_worker.js', document.baseURI));
   slot = {worker, pending:null, stopped:false};
   workers.set(req.id,slot);
   assets ||= Promise.all([
    fetch(new URL('assets/assets/book/openings.txt',document.baseURI), {signal:AbortSignal.timeout(10000)}).then(r=>r.ok?r.text():''),
    fetch(new URL('tablebase.txt',document.baseURI), {signal:AbortSignal.timeout(10000)}).then(r=>r.ok?r.text():null)
   ]).catch(()=>['',null]);
   const [book,tablebase] = await assets;
   if (slot.stopped) return empty;
   worker.postMessage(JSON.stringify({init:true,book,tablebase}));
  }
  if (slot.stopped) return empty;
  return new Promise(resolve=>{
   const done = data => { clearTimeout(timer); slot.pending=null; resolve(data); };
   const timer = setTimeout(()=>{ window.puzzlecubStopSearch(req.id); },20000);
   slot.pending = done;
   slot.worker.onmessage = e => done(e.data);
   slot.worker.onerror = () => window.puzzlecubStopSearch(req.id);
   slot.worker.postMessage(raw);
  });
 };
 window.puzzlecubStopSearch = id => {
  const slot=workers.get(id); if(!slot)return;
  slot.stopped=true;slot.worker.terminate();slot.pending?.(empty);workers.delete(id);
 };
 window.addEventListener('pagehide',()=>{for(const id of workers.keys())window.puzzlecubStopSearch(id);});
})();
