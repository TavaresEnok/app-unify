import type {
  FunctionRequest,
  FunctionRequestPayloadMap,
  FunctionRequestType,
} from "../contracts";

export interface RequestContext<T extends FunctionRequestType = FunctionRequestType> {
  requestId: string;
  type: T;
  requesterUid: string;
  payload: FunctionRequestPayloadMap[T];
}

export type RequestHandler<T extends FunctionRequestType = FunctionRequestType> = (
  context: RequestContext<T>,
) => Promise<unknown>;

export function toRequestContext<T extends FunctionRequestType>(
  requestId: string,
  request: FunctionRequest<T>,
): RequestContext<T> {
  return {
    requestId,
    type: request.type,
    requesterUid: request.requesterUid,
    payload: request.payload,
  };
}
