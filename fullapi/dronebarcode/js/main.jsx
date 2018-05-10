import React from 'react';
import ReactDOM from 'react-dom';
import Posts from './posts';


ReactDOM.render(
  // Renders the 'reactPostInfo' element using the Posts class on url '/riis'
  <Posts url="/riis" />,
  document.getElementById('reactPostInfo'),
);
