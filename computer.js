/* Separate UCI worker; no chess state or rendering lives in the engine. */
(() => {
  let worker = null, timer = null, generation = 0, result = null;
  function cancel() {
    generation++;
    clearTimeout(timer);
    if (worker) worker.terminate();
    worker = null;
    result = null;
  }
  window.shatranjComputer = {
    cancel,
    poll() { const value = result; result = null; return JSON.stringify(value); },
    search(fen, level, legalMoves) {
      cancel();
      const id = generation;
      const finish = value => {
        if (id !== generation) return;
        clearTimeout(timer);
        if (worker) worker.terminate();
        worker = null;
        result = {fen, ...value};
      };
      try {
        const legal = JSON.parse(legalMoves);
        if (!legal.length || !legal.every(m => /^[a-h][1-8][a-h][1-8][qrbn]?$/.test(m))) throw Error('Invalid legal moves');
        level = Math.max(1, Math.min(10, Number(level) || 1));
        worker = new Worker('stockfish/stockfish-19-lite-single.js');
        timer = setTimeout(() => finish({error:'The computer could not respond. Please retry.'}), 30000);
        worker.onerror = () => finish({error:'Could not load Stockfish. Check your connection and retry.'});
        let state = 'uci';
        worker.onmessage = event => {
          if (id !== generation) return;
          for (const line of String(event.data).split('\n')) {
            if (line.trim() === 'uciok' && state === 'uci') {
              state = 'ready';
              worker.postMessage('setoption name Hash value 16');
              worker.postMessage('setoption name Skill Level value ' + Math.round((level-1)*20/9));
              worker.postMessage('isready');
            } else if (line.trim() === 'readyok' && state === 'ready') {
              state = 'search';
              worker.postMessage('position fen ' + fen);
              worker.postMessage('go movetime ' + (250 + level*100) + ' depth ' + (3 + level) + ' searchmoves ' + legal.join(' '));
            } else if (line.startsWith('bestmove ') && state === 'search') {
              const move = line.split(/\s+/)[1];
              finish(legal.includes(move) ? {move} : {error:'The computer returned an invalid move. Please retry.'});
              return;
            }
          }
        };
        worker.postMessage('uci');
      } catch (e) { finish({error:'Stockfish is unavailable in this browser. Please retry or use local two-player.'}); }
    }
  };
})();
