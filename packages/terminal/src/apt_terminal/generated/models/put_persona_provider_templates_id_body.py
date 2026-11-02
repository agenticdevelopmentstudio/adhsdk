from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.put_persona_provider_templates_id_body_modalities_type_0_item import (
    PutPersonaProviderTemplatesIdBodyModalitiesType0Item,
)
from ..models.put_persona_provider_templates_id_body_provider_kind import (
    PutPersonaProviderTemplatesIdBodyProviderKind,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.provider_connection_spec_type_0 import ProviderConnectionSpecType0
    from ..models.template_available_via_type_0 import TemplateAvailableViaType0
    from ..models.template_sync_keys_type_0 import TemplateSyncKeysType0


T = TypeVar("T", bound="PutPersonaProviderTemplatesIdBody")


@_attrs_define
class PutPersonaProviderTemplatesIdBody:
    """
    Attributes:
        provider_kind (PutPersonaProviderTemplatesIdBodyProviderKind | Unset):
        name (str | Unset):
        base_url (str | Unset):
        documentation_url (None | str | Unset):
        status_url (None | str | Unset):
        connection_spec (None | ProviderConnectionSpecType0 | Unset):
        sync_keys (None | TemplateSyncKeysType0 | Unset): Operator-only upstream sync mapping — never present on public
            reads.
        available_via (None | TemplateAvailableViaType0 | Unset): Set ⇒ informational template: no first-party API;
            connect via the named templates.
        modalities (list[PutPersonaProviderTemplatesIdBodyModalitiesType0Item] | None | Unset):
        models (list[str] | Unset): Model names. On create: the initial model list. On update: the FULL desired set
            (matching rows kept, missing inserted, absent deleted); omit to leave models unchanged.
    """

    provider_kind: PutPersonaProviderTemplatesIdBodyProviderKind | Unset = UNSET
    name: str | Unset = UNSET
    base_url: str | Unset = UNSET
    documentation_url: None | str | Unset = UNSET
    status_url: None | str | Unset = UNSET
    connection_spec: None | ProviderConnectionSpecType0 | Unset = UNSET
    sync_keys: None | TemplateSyncKeysType0 | Unset = UNSET
    available_via: None | TemplateAvailableViaType0 | Unset = UNSET
    modalities: list[PutPersonaProviderTemplatesIdBodyModalitiesType0Item] | None | Unset = UNSET
    models: list[str] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.provider_connection_spec_type_0 import (
            ProviderConnectionSpecType0,
        )
        from ..models.template_available_via_type_0 import (
            TemplateAvailableViaType0,
        )
        from ..models.template_sync_keys_type_0 import TemplateSyncKeysType0

        provider_kind: str | Unset = UNSET
        if not isinstance(self.provider_kind, Unset):
            provider_kind = self.provider_kind.value

        name = self.name

        base_url = self.base_url

        documentation_url: None | str | Unset
        if isinstance(self.documentation_url, Unset):
            documentation_url = UNSET
        else:
            documentation_url = self.documentation_url

        status_url: None | str | Unset
        if isinstance(self.status_url, Unset):
            status_url = UNSET
        else:
            status_url = self.status_url

        connection_spec: dict[str, Any] | None | Unset
        if isinstance(self.connection_spec, Unset):
            connection_spec = UNSET
        elif isinstance(self.connection_spec, ProviderConnectionSpecType0):
            connection_spec = self.connection_spec.to_dict()
        else:
            connection_spec = self.connection_spec

        sync_keys: dict[str, Any] | None | Unset
        if isinstance(self.sync_keys, Unset):
            sync_keys = UNSET
        elif isinstance(self.sync_keys, TemplateSyncKeysType0):
            sync_keys = self.sync_keys.to_dict()
        else:
            sync_keys = self.sync_keys

        available_via: dict[str, Any] | None | Unset
        if isinstance(self.available_via, Unset):
            available_via = UNSET
        elif isinstance(self.available_via, TemplateAvailableViaType0):
            available_via = self.available_via.to_dict()
        else:
            available_via = self.available_via

        modalities: list[str] | None | Unset
        if isinstance(self.modalities, Unset):
            modalities = UNSET
        elif isinstance(self.modalities, list):
            modalities = []
            for modalities_type_0_item_data in self.modalities:
                modalities_type_0_item = modalities_type_0_item_data.value
                modalities.append(modalities_type_0_item)

        else:
            modalities = self.modalities

        models: list[str] | Unset = UNSET
        if not isinstance(self.models, Unset):
            models = self.models

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if provider_kind is not UNSET:
            field_dict["providerKind"] = provider_kind
        if name is not UNSET:
            field_dict["name"] = name
        if base_url is not UNSET:
            field_dict["baseUrl"] = base_url
        if documentation_url is not UNSET:
            field_dict["documentationUrl"] = documentation_url
        if status_url is not UNSET:
            field_dict["statusUrl"] = status_url
        if connection_spec is not UNSET:
            field_dict["connectionSpec"] = connection_spec
        if sync_keys is not UNSET:
            field_dict["syncKeys"] = sync_keys
        if available_via is not UNSET:
            field_dict["availableVia"] = available_via
        if modalities is not UNSET:
            field_dict["modalities"] = modalities
        if models is not UNSET:
            field_dict["models"] = models

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.provider_connection_spec_type_0 import (
            ProviderConnectionSpecType0,
        )
        from ..models.template_available_via_type_0 import (
            TemplateAvailableViaType0,
        )
        from ..models.template_sync_keys_type_0 import TemplateSyncKeysType0

        d = dict(src_dict)
        _provider_kind = d.pop("providerKind", UNSET)
        provider_kind: PutPersonaProviderTemplatesIdBodyProviderKind | Unset
        if isinstance(_provider_kind, Unset):
            provider_kind = UNSET
        else:
            provider_kind = PutPersonaProviderTemplatesIdBodyProviderKind(_provider_kind)

        name = d.pop("name", UNSET)

        base_url = d.pop("baseUrl", UNSET)

        def _parse_documentation_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        documentation_url = _parse_documentation_url(d.pop("documentationUrl", UNSET))

        def _parse_status_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        status_url = _parse_status_url(d.pop("statusUrl", UNSET))

        def _parse_connection_spec(data: object) -> None | ProviderConnectionSpecType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_provider_connection_spec_type_0 = (
                    ProviderConnectionSpecType0.from_dict(data)
                )

                return componentsschemas_provider_connection_spec_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | ProviderConnectionSpecType0 | Unset, data)

        connection_spec = _parse_connection_spec(d.pop("connectionSpec", UNSET))

        def _parse_sync_keys(data: object) -> None | TemplateSyncKeysType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_template_sync_keys_type_0 = TemplateSyncKeysType0.from_dict(data)

                return componentsschemas_template_sync_keys_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | TemplateSyncKeysType0 | Unset, data)

        sync_keys = _parse_sync_keys(d.pop("syncKeys", UNSET))

        def _parse_available_via(data: object) -> None | TemplateAvailableViaType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_template_available_via_type_0 = (
                    TemplateAvailableViaType0.from_dict(data)
                )

                return componentsschemas_template_available_via_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | TemplateAvailableViaType0 | Unset, data)

        available_via = _parse_available_via(d.pop("availableVia", UNSET))

        def _parse_modalities(
            data: object,
        ) -> list[PutPersonaProviderTemplatesIdBodyModalitiesType0Item] | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, list):
                    raise TypeError()
                modalities_type_0 = []
                _modalities_type_0 = data
                for modalities_type_0_item_data in _modalities_type_0:
                    modalities_type_0_item = PutPersonaProviderTemplatesIdBodyModalitiesType0Item(
                        modalities_type_0_item_data
                    )

                    modalities_type_0.append(modalities_type_0_item)

                return modalities_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                list[PutPersonaProviderTemplatesIdBodyModalitiesType0Item] | None | Unset, data
            )

        modalities = _parse_modalities(d.pop("modalities", UNSET))

        models = cast(list[str], d.pop("models", UNSET))

        put_persona_provider_templates_id_body = cls(
            provider_kind=provider_kind,
            name=name,
            base_url=base_url,
            documentation_url=documentation_url,
            status_url=status_url,
            connection_spec=connection_spec,
            sync_keys=sync_keys,
            available_via=available_via,
            modalities=modalities,
            models=models,
        )

        put_persona_provider_templates_id_body.additional_properties = d
        return put_persona_provider_templates_id_body

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
