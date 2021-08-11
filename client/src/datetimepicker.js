import React, { Component } from 'react';
import DateTimePicker from 'react-datetime-picker';
 
class MyApp extends Component {

  constructor (props) {
    super(props);
    this.state = {
        value: new Date()
    };
  }

  render() {
    return (
      <div>
        <DateTimePicker
          onChange={date=>{ 
              this.setState({value: date});
              this.props.onDateChange(date);
          }}
          value={this.state.value}
        />
      </div>
    );
  }
}

export default MyApp;