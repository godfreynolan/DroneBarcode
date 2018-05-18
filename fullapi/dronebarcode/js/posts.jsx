import React, { Component } from 'react';
import PropTypes from 'prop-types';

import { Connector } from 'mqtt-react';

import _mqttHandler from './mqttHandler.jsx';
import {subscribe} from 'mqtt-react';


class Posts extends Component {
  /* Display postid and url for posts
   * Reference on forms https://facebook.github.io/react/docs/forms.html
   */

  constructor(props) {
    // Initialize mutable state
    super(props);
    this.state = { data: [] };
    this.fetchNext = this.fetchNext.bind(this);
    this.customDispatch = this.customDispatch.bind(this);
    this.MessageContainer = subscribe({topic: 'barcode', dispatch: this.customDispatch})(_mqttHandler);
  }

  customDispatch(topic, message, packet) {
    console.log(`dispatch ${message}`);
    console.log(`${JSON.stringify(this.props)}`);
    this.setState(prevState => ({
      data: prevState.data.concat(message.toString('utf8')),
    }));
  }

  componentDidMount() {
    // On mount, load all posts
    /*fetch(this.props.url, { credentials: 'same-origin' })
      .then((response) => {
        if (!response.ok) throw Error(response.statusText);
        return response.json();
      })
      .then((data) => {
        if (performance.navigation.type === 2) {
          this.setState(history.state);
        } else {
          this.setState({
            data: data.chain,
          });
          history.pushState(this.state, '');
          // Check for new posts after a short delay
          //setTimeout(this.fetchNext, 1000);
        }
      })
      .catch(error => console.log(error)); // eslint-disable-line no-console*/
  }

  fetchNext() {
    // Every few seconds checks for updates
    fetch(this.props.url, { credentials: 'same-origin' })
      .then((response) => {
        if (!response.ok) throw Error(response.statusText);
        return response.json();
      })
      .then((data) => {
        this.setState({
          data: data.chain,
        });
        // Delay in between checks
        setTimeout(this.fetchNext, 1000);
      })
      .catch(error => console.log(error)); // eslint-disable-line no-console
  }

  render() {
    // Creates each of the posts
    /*const posts = this.state.data.map(post => (
      <div className="post">
        <div className="barcode">
          <span>DATA:{post.bcdata}</span><br/>
          <span>BLOCK:<font color={post.bchash.substring(4,10)}>{post.bchash}</font></span><br/>
          <span>PREVIOUS:<font color={post.bcprevhash.substring(4,10)}>{post.bcprevhash}</font></span><br/>
        </div>
      </div>
    ));*/
    console.log(`${JSON.stringify(this.state.data)}`);

    const posts = this.state.data.map(post => (
      <div className="post">
        <div className="barcode">
          <span>DATA:{post}</span><br/>
        </div>
      </div>
    ));

    // Renders all of the posts
    return (
      <div>
        {posts}
        <Connector mqttProps="mqtt://10.5.2.16:1884">
        <this.MessageContainer/>
        </Connector>
        
      </div>
    );
  }
}

Posts.propTypes = {
  url: PropTypes.string.isRequired,
};

export default Posts;
