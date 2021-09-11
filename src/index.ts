import { Elm } from './Main.elm'

const app = Elm.Main.init({
  node: document.getElementById('app'),
  flags: JSON.parse(localStorage.getItem('todos')),
})

app.ports.save.subscribe((data) => {
  localStorage.addItem('todos', JSON.stringify(data))
})
