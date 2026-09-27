import React, {useEffect,useState} from 'react';
import {createRoot} from 'react-dom/client';
import './style.css';
declare global { interface Window { GetParentResourceName?:()=>string } }
type Session={id:string;hostage:number;name:string;role:'hostage'|'captor';hands:boolean;captors:{id:number;name:string}[];offer:false|{officer:number}};
type Offer={hostage:number;name:string;seconds:number};
async function nui(name:string,data:unknown={}) {
 if(!window.GetParentResourceName)return;
 const response=await fetch(`https://${window.GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});
 if(!response.ok)throw new Error('Interaction unavailable');
 return response.json();
}
function App(){
 const [session,setSession]=useState<Session|false>(false),[panel,setPanel]=useState(false),[threat,setThreat]=useState(false),[warning,setWarning]=useState(false),[offer,setOffer]=useState<Offer|false>(false);
 const [seconds,setSeconds]=useState(0),[notice,setNotice]=useState(''),[target,setTarget]=useState(''),[busy,setBusy]=useState(false);
 const [config,setConfig]=useState({warning:'',comply:'X',panel:'F6'});
 useEffect(()=>{
  const listener=(e:MessageEvent)=>{ const {type,data}=e.data??{};
   switch(type){case 'state':setSession(data);break;case 'panel':setPanel(data);break;case 'threat':setThreat(data);break;case 'warning':setWarning(data);break;case 'offer':setOffer(data);break;case 'protection':setSeconds(data);break;case 'notice':setNotice(data);break;case 'config':setConfig(data);break;}
  };
  const keyboard=(e:KeyboardEvent)=>{if(e.key==='Escape')void nui('close').catch(()=>setPanel(false));};
  window.addEventListener('message',listener);window.addEventListener('keydown',keyboard);
  void nui('ready').catch(()=>setNotice('Interface could not connect. Reopen the panel.'));
  const timer=setInterval(()=>{setSeconds(s=>Math.max(0,s-1));setOffer(o=>o?(o.seconds>1?{...o,seconds:o.seconds-1}:false):false)},1000);
  return()=>{window.removeEventListener('message',listener);window.removeEventListener('keydown',keyboard);clearInterval(timer)};
 },[]);
 useEffect(()=>{if(!notice)return;const timer=setTimeout(()=>setNotice(''),6500);return()=>clearTimeout(timer)},[notice]);
 async function action(action:string,id?:number){setBusy(true);try{await nui('action',{action,target:id})}catch{setNotice('Interaction failed. Try again.')}finally{setTimeout(()=>setBusy(false),800)}}
 const time=`${Math.floor(seconds/60).toString().padStart(2,'0')}:${(seconds%60).toString().padStart(2,'0')}`;
 return <>
 {warning&&<div className="warning" role="alert"><span className="alert-icon">!</span><div><b>VALUE YOUR LIFE</b><p>{config.warning}</p></div></div>}
 {notice&&<div className="toast" role="status">{notice}</div>}
 {(session||threat||seconds>0||offer)&&<aside className="status"><i className={seconds>0?'green':''}/><div><b>{session?(session.role==='hostage'?'HOSTAGE SESSION':'HOSTAGE SECURED'):threat?'YOU ARE BEING THREATENED':offer?'CUSTODY REQUEST':'HOSTAGE PROTECTION'}</b><span>{session?`#${session.hostage} · ${session.captors.length} captor${session.captors.length===1?'':'s'}`:threat?'Raise your hands and comply':offer?'Officer acceptance required':`${time} remaining`}</span></div><kbd>{threat&&!session?config.comply:config.panel}</kbd></aside>}
 {panel&&<main><header><div className="brand">D<span> / </span>HOSTAGE</div><button className="close" onClick={()=>void nui('close')}>×</button></header><div className="body"><div className="eyebrow">PLAYER INTERACTION</div><h1>{session?(session.role==='hostage'?'Stay calm. Stay alive.':'Manage the situation.'):offer?'Accept custody.':'Situation overview.'}</h1><p className="sub">{session?'Keep communication clear and follow your server’s roleplay rules.':'Aim a firearm at a player. Their hands-up response begins a tracked session.'}</p>
 {seconds>0&&<section className="protection"><span>Protected from another hostage session</span><strong>{time}</strong></section>}
 {offer&&<section><div className="eyebrow">POLICE HANDOVER · {offer.seconds}s</div><h2>{offer.name} <small>#{offer.hostage}</small></h2><p>Accepting ends this hostage session and starts their protection timer. Arrest and cuff handling remain with your police resource.</p><button disabled={busy} onClick={()=>void action('accept',offer.hostage)}>Accept custody</button></section>}
 {session&&<><section><div className="row"><div><div className="eyebrow">HOSTAGE</div><h2>{session.name} <small>#{session.hostage}</small></h2></div><span className="badge">{session.hands?'HANDS UP':'HANDS LOWERED'}</span></div><div className="people">{session.captors.map(c=><span key={c.id}>{c.name} <small>#{c.id}</small></span>)}</div></section>
 {session.role==='captor'?<section><label htmlFor="target">Nearby player server ID</label><input id="target" type="number" min="1" placeholder="Enter server ID" value={target} onChange={e=>setTarget(e.target.value)}/><div className="actions"><button disabled={busy||!target} onClick={()=>void action('handover',Number(target))}>Offer to officer</button><button className="secondary" disabled={busy||!target} onClick={()=>void action('invite',Number(target))}>Add armed captor</button></div>{session.offer&&<p>Awaiting officer #{session.offer.officer}’s acceptance.</p>}<button className="release" disabled={busy} onClick={()=>void action('release')}>Release hostage</button></section>:<section><p>You remain tracked until released, handed over, or declared dead. Lowering your hands does not end the session.</p><button disabled={busy} onClick={()=>void action('comply')}>{session.hands?'Lower hands':'Raise hands'}</button></section>}</>}
 {!session&&threat&&seconds===0&&<section><h2>You are at gunpoint.</h2><p>Raise your hands and comply with reasonable demands.</p><button disabled={busy} onClick={()=>void action('comply')}>Raise hands & comply</button></section>}
 {!session&&!threat&&!offer&&seconds===0&&<section className="empty">No active hostage interaction.<br/><small>Only real players can enter a session.</small></section>}
 <footer><span><kbd>{config.comply}</kbd> Hands up / down</span><span>ESC to close</span></footer></div></main>}
 </>;
}
createRoot(document.getElementById('root')!).render(<App/>);
