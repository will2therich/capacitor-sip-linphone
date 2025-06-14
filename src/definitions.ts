export interface SipLinphonePlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
