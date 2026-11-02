from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_project_templates_body import PostProjectTemplatesBody
from ...models.project_template import ProjectTemplate
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostProjectTemplatesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    kind: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params["kind"] = kind

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/project/templates",
        "params": params,
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | ProjectTemplate | None:
    if response.status_code == 201:
        response_201 = ProjectTemplate.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | ProjectTemplate]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostProjectTemplatesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    kind: str | Unset = UNSET,
) -> Response[Error | ProjectTemplate]:
    """Create a template in the workspace

     The body is validated against `kind` before it is stored, STRICTLY: an unrecognized key is a 400,
    because every key in a template body becomes something and silently dropping one would answer "your
    template is fine" and then build a board without the columns the author wrote. It is also what makes
    a kind mismatch detectable at all — a project body’s keys are all optional, so a work-item body sent
    under `kind: project` would otherwise be an empty-but-valid one. Requires the workspace’s projects C
    verb when creating into someone else’s workspace.

    Args:
        workspace (str | Unset):
        kind (str | Unset):
        body (PostProjectTemplatesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProjectTemplate]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
        kind=kind,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: PostProjectTemplatesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    kind: str | Unset = UNSET,
) -> Error | ProjectTemplate | None:
    """Create a template in the workspace

     The body is validated against `kind` before it is stored, STRICTLY: an unrecognized key is a 400,
    because every key in a template body becomes something and silently dropping one would answer "your
    template is fine" and then build a board without the columns the author wrote. It is also what makes
    a kind mismatch detectable at all — a project body’s keys are all optional, so a work-item body sent
    under `kind: project` would otherwise be an empty-but-valid one. Requires the workspace’s projects C
    verb when creating into someone else’s workspace.

    Args:
        workspace (str | Unset):
        kind (str | Unset):
        body (PostProjectTemplatesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProjectTemplate
    """

    return sync_detailed(
        client=client,
        body=body,
        workspace=workspace,
        kind=kind,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostProjectTemplatesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    kind: str | Unset = UNSET,
) -> Response[Error | ProjectTemplate]:
    """Create a template in the workspace

     The body is validated against `kind` before it is stored, STRICTLY: an unrecognized key is a 400,
    because every key in a template body becomes something and silently dropping one would answer "your
    template is fine" and then build a board without the columns the author wrote. It is also what makes
    a kind mismatch detectable at all — a project body’s keys are all optional, so a work-item body sent
    under `kind: project` would otherwise be an empty-but-valid one. Requires the workspace’s projects C
    verb when creating into someone else’s workspace.

    Args:
        workspace (str | Unset):
        kind (str | Unset):
        body (PostProjectTemplatesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProjectTemplate]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
        kind=kind,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostProjectTemplatesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    kind: str | Unset = UNSET,
) -> Error | ProjectTemplate | None:
    """Create a template in the workspace

     The body is validated against `kind` before it is stored, STRICTLY: an unrecognized key is a 400,
    because every key in a template body becomes something and silently dropping one would answer "your
    template is fine" and then build a board without the columns the author wrote. It is also what makes
    a kind mismatch detectable at all — a project body’s keys are all optional, so a work-item body sent
    under `kind: project` would otherwise be an empty-but-valid one. Requires the workspace’s projects C
    verb when creating into someone else’s workspace.

    Args:
        workspace (str | Unset):
        kind (str | Unset):
        body (PostProjectTemplatesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProjectTemplate
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
            workspace=workspace,
            kind=kind,
        )
    ).parsed
