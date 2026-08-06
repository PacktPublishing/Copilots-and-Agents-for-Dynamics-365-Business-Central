import { FluentProvider, webLightTheme } from '@fluentui/react-components';
import { ChatInterface } from './components/ChatInterface';

function App() {
  return (
    <FluentProvider theme={webLightTheme}>
      <ChatInterface />
    </FluentProvider>
  );
}

export default App;
