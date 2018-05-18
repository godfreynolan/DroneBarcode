import React, { Component } from 'react';
import PropTypes from 'prop-types';

import { Connector } from 'mqtt-react';

import _mqttHandler from './mqttHandler.jsx';
import {subscribe} from 'mqtt-react';


class Posts extends Component {
  /* Display blockchain information for barcodes
   * Reference on forms https://facebook.github.io/react/docs/forms.html
   */

  constructor(props) {
    // Initialize mutable state
    super(props);
    this.state = { data: [] };
    this.customDispatch = this.customDispatch.bind(this);
    this.MessageContainer = subscribe({
      topic: 'barcode', dispatch: this.customDispatch
    })(_mqttHandler);
  }

  componentDidMount() {
    // Populates the state on initial load with existing chain data
    fetch(this.props.url, { credentials: 'same-origin' })
      .then((response) => {
        if (!response.ok) throw Error(response.statusText);
        return response.json();
      })
      .then((data) => {
        this.setState({
          data: data.chain,
        });
      })
      .catch(error => console.log(error)); // eslint-disable-line no-console
  }

  customDispatch(topic, message, packet) {
    // Route barcode data to the mining server to append to blockchain
    const barcode = { data: message.toString('utf8') };
    fetch('/testmine', {
      credentials: 'same-origin',
      body: JSON.stringify(barcode),
      headers: {
        'content-type': 'application/json',
      },
      method: 'POST'
    })
      .then((response) => {
        if (!response.ok) throw Error(response.statusText);
        return response.json();
      })
      .then((data) => {
        let temp = [ data.block, ];
        this.setState( prevState => ({
          data: temp.concat(prevState.data),
        }));
      })
      .catch(error => console.log(error)); // eslint-disable-line no-console
  }

  render() {
    // Creates each of the posts
    const posts = this.state.data.map(post => (
      <div className="post">
        <div className="barcode">
          <span>
            DATA:{post.bcdata}
          </span><br/>
          <span>
            BLOCK:
            <font color={post.bchash.substring(4,10)}>{post.bchash}</font>
          </span><br/>
          <span>
            PREVIOUS:
            <font color={post.bcprevhash.substring(4,10)}>{post.bcprevhash}</font>
          </span><br/>
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
