import { Component } from 'react';

class TezosApp extends Component {
    constructor (props) {
      super(props);
      this.state = {
          data: null
      };
    }
    xtzPricefetch () {
        fetch('https://api-pub.bitfinex.com/v2/ticker/tXTZUSD')
          .then(res => res.json())
          .then(data => this.setState({data}));
    }
  }
  
  export default TezosApp;

