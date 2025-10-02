declare module 'langchain/llms/openai' {
  import { OpenAI } from 'langchain';
  export { OpenAI };
}

declare module 'langchain/prompts' {
  import { PromptTemplate } from 'langchain';
  export { PromptTemplate };
}

declare module 'langchain/chains' {
  import { LLMChain } from 'langchain';
  export { LLMChain };
}
