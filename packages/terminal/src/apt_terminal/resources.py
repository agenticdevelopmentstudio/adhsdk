from __future__ import annotations

from dataclasses import dataclass
from types import ModuleType

# Generated operation modules (auth domain): /v1/api_keys replaces /auth/tokens.
from apt_terminal.generated.api.auth import (
    delete_v1_api_keys_by_id,
    get_v1_api_keys,
    post_v1_api_keys,
)

# Generated operation modules (persona domain): /v1/ai_services, /v1/personas, /v1/models
# and /v1/provider_templates replace /persona/services, /persona/personas, /persona/models
# and /persona/provider-templates.
from apt_terminal.generated.api.persona import (
    delete_v1_ai_services_by_id,
    delete_v1_personas_by_id,
    get_v1_ai_services,
    get_v1_ai_services_by_id,
    get_v1_models,
    get_v1_personas,
    get_v1_personas_by_id,
    get_v1_provider_templates,
    post_v1_ai_services,
    post_v1_ai_services_by_id,
    post_v1_ai_services_by_id_connect,
    post_v1_ai_services_by_id_refresh_models,
    post_v1_personas,
    post_v1_personas_by_id,
)
from apt_terminal.generated.models.post_v1_ai_services_body import PostV1AiServicesBody
from apt_terminal.generated.models.post_v1_ai_services_by_id_body import (
    PostV1AiServicesByIdBody,
)

# `POST /v1/api_keys` accepts two bodies: Type0 is the old `/auth/tokens` shape (name,
# expires_at, scope) that `apt auth tokens create` has always sent; Type1 is the old
# ecosystem `/tokens` shape, which this CLI never exposed.
from apt_terminal.generated.models.post_v1_api_keys_body_type_0 import PostV1ApiKeysBodyType0
from apt_terminal.generated.models.post_v1_personas_body import PostV1PersonasBody
from apt_terminal.generated.models.post_v1_personas_by_id_body import PostV1PersonasByIdBody


@dataclass(frozen=True)
class Ops:
    list_: ModuleType | None = None
    get: ModuleType | None = None
    create: ModuleType | None = None
    update: ModuleType | None = None
    delete: ModuleType | None = None


@dataclass(frozen=True)
class Action:
    """A named per-object command.

    `id_param` is set when /v1 takes the object's id as a QUERY parameter rather than in the
    path — e.g. a service's models are `GET /v1/models?service=<id>`, not a nested route.
    """

    name: str
    op: ModuleType
    help: str = ""
    id_param: str | None = None


@dataclass(frozen=True)
class Resource:
    domain: str
    name: str
    ops: Ops
    create_body: type | None = None
    update_body: type | None = None
    actions: tuple[Action, ...] = ()


PERSONA: tuple[Resource, ...] = (
    Resource(
        domain="persona",
        name="services",
        ops=Ops(
            list_=get_v1_ai_services,
            get=get_v1_ai_services_by_id,
            create=post_v1_ai_services,
            update=post_v1_ai_services_by_id,
            delete=delete_v1_ai_services_by_id,
        ),
        create_body=PostV1AiServicesBody,
        update_body=PostV1AiServicesByIdBody,
        actions=(
            Action("connect", post_v1_ai_services_by_id_connect, "Probe the provider connection"),
            Action("models", get_v1_models, "List the provider's models", id_param="service"),
            Action(
                "models-refresh",
                post_v1_ai_services_by_id_refresh_models,
                "Re-fetch the model catalog",
            ),
        ),
    ),
    Resource(
        domain="persona",
        name="personas",
        ops=Ops(
            list_=get_v1_personas,
            get=get_v1_personas_by_id,
            create=post_v1_personas,
            update=post_v1_personas_by_id,
            delete=delete_v1_personas_by_id,
        ),
        create_body=PostV1PersonasBody,
        update_body=PostV1PersonasByIdBody,
    ),
    Resource(
        domain="persona",
        name="models",
        ops=Ops(list_=get_v1_models),
    ),
    # `persona templates` lists the redacting provider-templates catalog.
    Resource(
        domain="persona",
        name="templates",
        ops=Ops(list_=get_v1_provider_templates),
    ),
)

AUTH_TOKENS: tuple[Resource, ...] = (
    Resource(
        domain="auth",
        name="tokens",
        ops=Ops(
            list_=get_v1_api_keys,
            create=post_v1_api_keys,
            delete=delete_v1_api_keys_by_id,
        ),
        create_body=PostV1ApiKeysBodyType0,
    ),
)

ALL_DOMAINS: dict[str, tuple[Resource, ...]] = {"persona": PERSONA}
