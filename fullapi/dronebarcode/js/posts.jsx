import React from 'react';
import PropTypes from 'prop-types';

class Posts extends React.Component {
  /* Display postid and url for posts
   * Reference on forms https://facebook.github.io/react/docs/forms.html
   */
  constructor(props) {
    // Initialize mutable state
    super(props);
    this.state = { data: [] };
    this.fetchNext = this.fetchNext.bind(this);
  }

  componentDidMount() {
    // On mount, load all posts
    fetch(this.props.url, { credentials: 'same-origin' })
      .then((response) => {
        if (!response.ok) throw Error(response.statusText);
        return response.json();
      })
      .then((data) => {
        if (performance.navigation.type === 2) {
          this.setState(history.state);
        } else {
          this.setState({
            data: data.data,
          });
          history.pushState(this.state, '');
          // Check for new posts after a short delay
          setTimeout(this.fetchNext, 3000);
        }
      })
      .catch(error => console.log(error)); // eslint-disable-line no-console
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
          data: data.data,
        });
        // Delay in between checks
        setTimeout(this.fetchNext, 3000);
      })
      .catch(error => console.log(error)); // eslint-disable-line no-console
  }

  render() {
    // Creates each of the posts
    const posts = this.state.data.map(post => (
      <div className="post">
        <div className="barcode">
          DATA:{post.txdata}<br/>
          BLOCK:{post.bchash}<br/>
        </div>
      </div>
    ));

    // Renders all of the posts
    return (
      <div>
        {posts}
      </div>
    );
  }
}

Posts.propTypes = {
  url: PropTypes.string.isRequired,
};

export default Posts;
