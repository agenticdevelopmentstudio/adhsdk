from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_auth_login_mfa_sms_send_body import PostAuthLoginMfaSmsSendBody
from ...models.post_auth_login_mfa_sms_send_response_202 import PostAuthLoginMfaSmsSendResponse202
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostAuthLoginMfaSmsSendBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/auth/login/mfa/sms/send",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostAuthLoginMfaSmsSendResponse202 | None:
    if response.status_code == 202:
        response_202 = PostAuthLoginMfaSmsSendResponse202.from_dict(response.json())

        return response_202

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if response.status_code == 422:
        response_422 = Error.from_dict(response.json())

        return response_422

    if response.status_code == 429:
        response_429 = Error.from_dict(response.json())

        return response_429

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PostAuthLoginMfaSmsSendResponse202]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostAuthLoginMfaSmsSendBody | Unset = UNSET,
) -> Response[Error | PostAuthLoginMfaSmsSendResponse202]:
    """Send the SMS login code to the verified primary phone

    Args:
        body (PostAuthLoginMfaSmsSendBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostAuthLoginMfaSmsSendResponse202]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient | Client,
    body: PostAuthLoginMfaSmsSendBody | Unset = UNSET,
) -> Error | PostAuthLoginMfaSmsSendResponse202 | None:
    """Send the SMS login code to the verified primary phone

    Args:
        body (PostAuthLoginMfaSmsSendBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostAuthLoginMfaSmsSendResponse202
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostAuthLoginMfaSmsSendBody | Unset = UNSET,
) -> Response[Error | PostAuthLoginMfaSmsSendResponse202]:
    """Send the SMS login code to the verified primary phone

    Args:
        body (PostAuthLoginMfaSmsSendBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostAuthLoginMfaSmsSendResponse202]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    body: PostAuthLoginMfaSmsSendBody | Unset = UNSET,
) -> Error | PostAuthLoginMfaSmsSendResponse202 | None:
    """Send the SMS login code to the verified primary phone

    Args:
        body (PostAuthLoginMfaSmsSendBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostAuthLoginMfaSmsSendResponse202
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
