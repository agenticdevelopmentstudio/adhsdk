from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostPersonaProviderTemplatesIdVerifyBody")


@_attrs_define
class PostPersonaProviderTemplatesIdVerifyBody:
    """
    Attributes:
        api_key (str): Used for this one probe request only; not persisted.
        base_url (str | Unset): Optional base_url override for the probe — supply a concrete URL to verify a template
            whose stored base_url still carries url-var placeholders.
    """

    api_key: str
    base_url: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        api_key = self.api_key

        base_url = self.base_url

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "apiKey": api_key,
            }
        )
        if base_url is not UNSET:
            field_dict["baseUrl"] = base_url

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        api_key = d.pop("apiKey")

        base_url = d.pop("baseUrl", UNSET)

        post_persona_provider_templates_id_verify_body = cls(
            api_key=api_key,
            base_url=base_url,
        )

        post_persona_provider_templates_id_verify_body.additional_properties = d
        return post_persona_provider_templates_id_verify_body

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
