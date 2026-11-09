from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.provider_template_modalities_type_0_item import ProviderTemplateModalitiesType0Item
from ..models.provider_template_provider_kind import ProviderTemplateProviderKind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.provider_connection_spec_type_0 import ProviderConnectionSpecType0
    from ..models.provider_template_model import ProviderTemplateModel
    from ..models.template_available_via_type_0 import TemplateAvailableViaType0


T = TypeVar("T", bound="PostV1ProviderTemplatesResponse201")


@_attrs_define
class PostV1ProviderTemplatesResponse201:
    """
    Attributes:
        id (str):
        provider_kind (ProviderTemplateProviderKind):
        name (str):
        base_url (str):
        documentation_url (None | str):
        status_url (None | str):
        connection_spec (None | ProviderConnectionSpecType0):
        available_via (None | TemplateAvailableViaType0): Set ⇒ informational template: no first-party API; connect via
            the named templates.
        modalities (list[ProviderTemplateModalitiesType0Item] | None):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        models (list[ProviderTemplateModel]):
        object_ (Literal['provider_template'] | Unset):
    """

    id: str
    provider_kind: ProviderTemplateProviderKind
    name: str
    base_url: str
    documentation_url: None | str
    status_url: None | str
    connection_spec: None | ProviderConnectionSpecType0
    available_via: None | TemplateAvailableViaType0
    modalities: list[ProviderTemplateModalitiesType0Item] | None
    created: int
    updated: int
    models: list[ProviderTemplateModel]
    object_: Literal["provider_template"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.provider_connection_spec_type_0 import (
            ProviderConnectionSpecType0,
        )
        from ..models.template_available_via_type_0 import (
            TemplateAvailableViaType0,
        )

        id = self.id

        provider_kind = self.provider_kind.value

        name = self.name

        base_url = self.base_url

        documentation_url: None | str
        documentation_url = self.documentation_url

        status_url: None | str
        status_url = self.status_url

        connection_spec: dict[str, Any] | None
        if isinstance(self.connection_spec, ProviderConnectionSpecType0):
            connection_spec = self.connection_spec.to_dict()
        else:
            connection_spec = self.connection_spec

        available_via: dict[str, Any] | None
        if isinstance(self.available_via, TemplateAvailableViaType0):
            available_via = self.available_via.to_dict()
        else:
            available_via = self.available_via

        modalities: list[str] | None
        if isinstance(self.modalities, list):
            modalities = []
            for modalities_type_0_item_data in self.modalities:
                modalities_type_0_item = modalities_type_0_item_data.value
                modalities.append(modalities_type_0_item)

        else:
            modalities = self.modalities

        created = self.created

        updated = self.updated

        models = []
        for models_item_data in self.models:
            models_item = models_item_data.to_dict()
            models.append(models_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "provider_kind": provider_kind,
                "name": name,
                "base_url": base_url,
                "documentation_url": documentation_url,
                "status_url": status_url,
                "connection_spec": connection_spec,
                "available_via": available_via,
                "modalities": modalities,
                "created": created,
                "updated": updated,
                "models": models,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.provider_connection_spec_type_0 import (
            ProviderConnectionSpecType0,
        )
        from ..models.provider_template_model import ProviderTemplateModel
        from ..models.template_available_via_type_0 import (
            TemplateAvailableViaType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        provider_kind = ProviderTemplateProviderKind(d.pop("provider_kind"))

        name = d.pop("name")

        base_url = d.pop("base_url")

        def _parse_documentation_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        documentation_url = _parse_documentation_url(d.pop("documentation_url"))

        def _parse_status_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        status_url = _parse_status_url(d.pop("status_url"))

        def _parse_connection_spec(data: object) -> None | ProviderConnectionSpecType0:
            if data is None:
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
            return cast(None | ProviderConnectionSpecType0, data)

        connection_spec = _parse_connection_spec(d.pop("connection_spec"))

        def _parse_available_via(data: object) -> None | TemplateAvailableViaType0:
            if data is None:
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
            return cast(None | TemplateAvailableViaType0, data)

        available_via = _parse_available_via(d.pop("available_via"))

        def _parse_modalities(data: object) -> list[ProviderTemplateModalitiesType0Item] | None:
            if data is None:
                return data
            try:
                if not isinstance(data, list):
                    raise TypeError()
                modalities_type_0 = []
                _modalities_type_0 = data
                for modalities_type_0_item_data in _modalities_type_0:
                    modalities_type_0_item = ProviderTemplateModalitiesType0Item(
                        modalities_type_0_item_data
                    )

                    modalities_type_0.append(modalities_type_0_item)

                return modalities_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(list[ProviderTemplateModalitiesType0Item] | None, data)

        modalities = _parse_modalities(d.pop("modalities"))

        created = d.pop("created")

        updated = d.pop("updated")

        models = []
        _models = d.pop("models")
        for models_item_data in _models:
            models_item = ProviderTemplateModel.from_dict(models_item_data)

            models.append(models_item)

        object_ = cast(Literal["provider_template"] | Unset, d.pop("object", UNSET))
        if object_ != "provider_template" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'provider_template', got '{object_}'")

        post_v1_provider_templates_response_201 = cls(
            id=id,
            provider_kind=provider_kind,
            name=name,
            base_url=base_url,
            documentation_url=documentation_url,
            status_url=status_url,
            connection_spec=connection_spec,
            available_via=available_via,
            modalities=modalities,
            created=created,
            updated=updated,
            models=models,
            object_=object_,
        )

        post_v1_provider_templates_response_201.additional_properties = d
        return post_v1_provider_templates_response_201

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
